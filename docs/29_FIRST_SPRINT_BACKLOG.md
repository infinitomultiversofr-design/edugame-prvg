# 29 — Primeira Sprint — Backlog Executável

Objetivo da Sprint 1:
**fundação segura e executável**, sem tentar construir o produto inteiro.

## S1-01 Repo Foundation
- Next/React/TS strict;
- Tailwind;
- aliases;
- lint;
- formatter;
- env validation;
- Vitest;
- Playwright;
- CI.

Aceite:
build/lint/typecheck/test verdes.

## S1-02 Environments
- dev;
- staging;
- production strategy;
- `.env.example`;
- secret handling.

## S1-03 Supabase Baseline
- migrations;
- extensions necessárias;
- schema base school/auth/student/class;
- migration naming;
- seed dev.

## S1-04 Auth Student
- ID EduGame + PIN;
- sessão;
- logout;
- bloqueio de signup público;
- route guard.

## S1-05 RBAC + RLS Smoke
- membership;
- enrollment;
- fixtures roles;
- testes estudante A não lê B.

## S1-06 Design Tokens
- CSS variables/tokens;
- Button/Card/Input/Toast;
- reduced motion;
- focus states.

## S1-07 App Shell
- student shell;
- adult shell placeholder;
- 360/1024 layouts;
- loading/error/offline banner.

## S1-08 Feature Flags
- schema;
- resolver;
- cache;
- audit-ready structure.

## S1-09 Error Contract
- typed domain errors;
- mapping pt-BR;
- request id.

## S1-10 Observability Skeleton
- structured server logger;
- health endpoint;
- client error boundary sem segredos.

## Sprint Gate
- deploy staging;
- aluno teste faz login;
- aluno A não acessa B;
- shell carrega em mobile mínimo;
- nenhum WebGL no critical path;
- Playwright auth verde;
- RLS tests verdes;
- documentação de setup reproduzível.
