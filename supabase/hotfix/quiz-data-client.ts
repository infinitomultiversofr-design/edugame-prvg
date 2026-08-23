/**
 * Camada de dados do /quiz — substitui o acesso direto às tabelas.
 *
 * Onde colocar no projeto Lovable: src/lib/quizData.ts
 *
 * Depois de aplicar os dois SQL de hotfix, o papel `anon` não lê mais
 * classes/students/questions/rules nem escreve em quiz_responses/transactions.
 * Todo acesso do quiz passa por estas três RPCs.
 *
 * MUDANÇAS NECESSÁRIAS EM src/pages/Quiz.tsx
 *
 *   submitCode()   supabase.from("classes").select(...)      -> lookupClass(code)
 *                  supabase.from("students").select(...)        (vem junto no retorno)
 *
 *   pickStudent()  supabase.from("quiz_responses").select(...) -> startQuiz(studentId)
 *                  supabase.from("questions").select(...)        (a checagem semanal
 *                                                                 virou erro do servidor)
 *
 *   submitQuiz()   supabase.from("rules").select(...)        -> submitQuiz(studentId, answers)
 *                  supabase.from("quiz_responses").insert(...)
 *                  supabase.from("transactions").insert(...)
 *
 * A interface Question perde `correct_answer`, `correct_answer_normalized` e
 * `queue_order` — o servidor não manda mais isso antes da submissão. O gabarito
 * chega no retorno de submitQuiz(), por questão, já depois de gravada a resposta.
 *
 * normalizeAnswer() e getMondayISO() saem do Quiz.tsx: correção e semana agora
 * são decididas no servidor. Mantenha normalizeAnswer() só se ainda usar para
 * filtrar a busca de nome na lista.
 */

import { supabase } from "./supabase";

export interface QuizClass {
  id: string;
  name: string;
  grade: string;
}

export interface QuizStudent {
  id: string;
  name: string;
}

/** Sem gabarito: o servidor não envia a resposta correta antes da submissão. */
export interface QuizQuestion {
  id: string;
  subject: string;
  question_text: string;
  question_type: "multiple_choice" | "short_answer";
  options: string[] | null;
}

export interface QuizFeedback {
  question_id: string;
  subject: string;
  given: string;
  correct: boolean;
  pending: boolean;
  /** Só vem preenchido para questões objetivas, depois de gravada a resposta. */
  correct_answer: string | null;
}

/** Mensagens vindas do servidor, para traduzir na UI. */
export type QuizErrorCode =
  | "QUIZ_CODE_REQUIRED"
  | "CLASS_NOT_FOUND"
  | "CLASS_WITHOUT_YEAR_GROUP"
  | "STUDENT_NOT_FOUND"
  | "ALREADY_SUBMITTED_THIS_WEEK"
  | "ANSWERS_MUST_BE_ARRAY"
  | "TOO_MANY_ANSWERS"
  | "NO_VALID_ANSWERS";

export class QuizError extends Error {
  readonly code: QuizErrorCode | "UNKNOWN";
  constructor(code: QuizErrorCode | "UNKNOWN", message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = "QuizError";
  }
}

const KNOWN_CODES: readonly string[] = [
  "QUIZ_CODE_REQUIRED",
  "CLASS_NOT_FOUND",
  "CLASS_WITHOUT_YEAR_GROUP",
  "STUDENT_NOT_FOUND",
  "ALREADY_SUBMITTED_THIS_WEEK",
  "ANSWERS_MUST_BE_ARRAY",
  "TOO_MANY_ANSWERS",
  "NO_VALID_ANSWERS",
];

function toQuizError(error: { message?: string } | null): QuizError {
  const raw = error?.message ?? "";
  const found = KNOWN_CODES.find((c) => raw.includes(c));
  return new QuizError((found as QuizErrorCode) ?? "UNKNOWN", raw || undefined);
}

export const QUIZ_ERROR_MESSAGE: Record<QuizErrorCode | "UNKNOWN", string> = {
  QUIZ_CODE_REQUIRED: "Digite o código da turma.",
  CLASS_NOT_FOUND: "❌ Código não encontrado, confira com o professor",
  CLASS_WITHOUT_YEAR_GROUP: "❌ Esta turma ainda não tem questões cadastradas",
  STUDENT_NOT_FOUND: "❌ Aluno não encontrado ou inativo. Avise o professor.",
  ALREADY_SUBMITTED_THIS_WEEK: "Você já respondeu o quiz desta semana!",
  ANSWERS_MUST_BE_ARRAY: "Erro ao enviar as respostas. Tente novamente.",
  TOO_MANY_ANSWERS: "Erro ao enviar as respostas. Tente novamente.",
  NO_VALID_ANSWERS: "Ainda não há questões disponíveis. Avise o professor.",
  UNKNOWN: "Não foi possível concluir. Tente novamente.",
};

/** Turma + alunos ativos daquela turma, a partir do código. */
export async function lookupClass(
  quizCode: string
): Promise<{ klass: QuizClass; students: QuizStudent[] }> {
  const { data, error } = await supabase.rpc("quiz_lookup_class", {
    p_quiz_code: quizCode,
  });
  if (error) throw toQuizError(error);
  return {
    klass: data.class as QuizClass,
    students: (data.students ?? []) as QuizStudent[],
  };
}

/**
 * Questões da semana para o aluno. Lança ALREADY_SUBMITTED_THIS_WEEK se ele já
 * respondeu — a checagem semanal deixou de ser decisão do navegador.
 */
export async function startQuiz(studentId: string): Promise<QuizQuestion[]> {
  const { data, error } = await supabase.rpc("quiz_start", {
    p_student_id: studentId,
  });
  if (error) throw toQuizError(error);
  return (data ?? []) as QuizQuestion[];
}

/**
 * Envia as respostas. O servidor corrige, grava quiz_responses, lança os pontos
 * e devolve o resultado por questão. O cliente não calcula acerto nem escreve
 * no ledger.
 */
export async function submitQuiz(
  studentId: string,
  answers: Record<string, string>
): Promise<QuizFeedback[]> {
  const payload = Object.entries(answers).map(([question_id, answer]) => ({
    question_id,
    answer,
  }));

  const { data, error } = await supabase.rpc("quiz_submit", {
    p_student_id: studentId,
    p_answers: payload,
  });
  if (error) throw toQuizError(error);
  return (data ?? []) as QuizFeedback[];
}
