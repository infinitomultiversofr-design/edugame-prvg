/*
 * EDUGAME — M0 FOUNDATION
 *
 * INVARIANTES DE IDENTIDADE E AUTORIDADE
 * 1. Nenhuma identidade operacional usa serial/bigserial.
 *    PKs operacionais usam UUID; relações puramente associativas podem usar chaves compostas.
 * 2. Códigos humanos (turma, habilidade, ID EduGame etc.) não substituem FKs.
 * 3. O navegador nunca é autoridade para pontuação, acerto, desbloqueio ou identidade de outro usuário.
 * 4. Operações sensíveis posteriores devem ser server-authoritative, idempotentes e auditáveis.
 * 5. Entidades históricas são inativadas/arquivadas; não dependemos de DELETE CASCADE para “limpeza”.
 */

BEGIN;

CREATE TABLE public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  school_id uuid REFERENCES public.schools(id) ON DELETE SET NULL,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid,
  diff_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),

  -- Impede os erros mais óbvios. Sanitização profunda continua responsabilidade da aplicação.
  CONSTRAINT audit_metadata_no_raw_network_pii CHECK (
    NOT (metadata ?| ARRAY['ip', 'ip_address', 'raw_ip', 'user_agent', 'user_agent_raw'])
  )
);

CREATE INDEX audit_logs_user_idx ON public.audit_logs(user_id);
CREATE INDEX audit_logs_school_idx ON public.audit_logs(school_id);
CREATE INDEX audit_logs_action_idx ON public.audit_logs(action);
CREATE INDEX audit_logs_created_idx ON public.audit_logs(created_at DESC);

CREATE OR REPLACE FUNCTION private.audit_feature_flag_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_school uuid;
  v_resource uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_school := OLD.school_id;
    v_resource := OLD.id;

    INSERT INTO public.audit_logs (
      user_id, school_id, action, resource_type, resource_id,
      diff_summary, metadata
    ) VALUES (
      v_actor, v_school, 'feature_flag_override_deleted',
      'feature_flag_override', v_resource,
      jsonb_build_object(
        'enabled', OLD.enabled,
        'priority', OLD.priority
      ),
      jsonb_build_object('scope_type', OLD.scope_type)
    );

    RETURN OLD;
  END IF;

  v_school := NEW.school_id;
  v_resource := NEW.id;

  INSERT INTO public.audit_logs (
    user_id, school_id, action, resource_type, resource_id,
    diff_summary, metadata
  ) VALUES (
    v_actor,
    v_school,
    CASE WHEN TG_OP = 'INSERT'
      THEN 'feature_flag_override_created'
      ELSE 'feature_flag_override_updated'
    END,
    'feature_flag_override',
    v_resource,
    CASE WHEN TG_OP = 'INSERT'
      THEN jsonb_build_object(
        'enabled', NEW.enabled,
        'priority', NEW.priority
      )
      ELSE jsonb_build_object(
        'enabled_from', OLD.enabled,
        'enabled_to', NEW.enabled,
        'priority_from', OLD.priority,
        'priority_to', NEW.priority
      )
    END,
    jsonb_build_object('scope_type', NEW.scope_type)
  );

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.audit_feature_flag_change()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER feature_flag_overrides_audit
AFTER INSERT OR UPDATE OR DELETE
ON public.feature_flag_overrides
FOR EACH ROW EXECUTE FUNCTION private.audit_feature_flag_change();

COMMIT;
