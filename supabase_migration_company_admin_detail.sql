-- Migración: ficha completa de empresa en el panel admin (admin.empresa.html)
-- Ejecutar en el SQL Editor de Supabase (proyecto awuhvewotmwelurmjvmu)
--
-- Contexto: al dar clic en una empresa en admin.empresas.html se abre una
-- página con toda su ficha: datos fiscales y dirección, financiero, área
-- comercial, éxito del cliente, plan y notas internas. Los datos que se
-- consultan o filtran van en columnas; los interruptores de configuración
-- (flujos de aprobación, control de dotación, módulos contratados…) van en
-- admin_settings (jsonb) para poder sumar nuevos sin migrar.

alter table company_profile
  -- Datos generales
  add column if not exists subsector text,
  add column if not exists tax_regime text,
  add column if not exists cfdi_use text,
  add column if not exists postal_code text,
  add column if not exists street text,
  add column if not exists ext_number text,
  add column if not exists int_number text,
  add column if not exists neighborhood text,
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists phone text,
  add column if not exists phone_2 text,
  add column if not exists billing_email text,
  add column if not exists account_status text default 'activo',
  add column if not exists contract_signed_at date,
  add column if not exists churn_at date,
  -- Financiero
  add column if not exists billing_enabled boolean default true,
  add column if not exists payment_methods text[] default '{}',
  add column if not exists credit_days integer,
  add column if not exists credit_limit numeric,
  add column if not exists monthly_budget numeric,
  -- Área comercial
  add column if not exists business_group text,
  add column if not exists first_presentation_at date,
  add column if not exists closer text,
  add column if not exists sdr text,
  add column if not exists implementation_analyst text,
  add column if not exists acquisition_channel text,
  add column if not exists employees_range text,
  add column if not exists work_centers_count integer,
  -- Plan / responsabilidad / éxito del cliente
  add column if not exists plan text,
  add column if not exists account_owner text,
  add column if not exists renewal_at date,
  add column if not exists cs_owner text,
  add column if not exists cs_category text,
  add column if not exists manual_review boolean default false,
  add column if not exists attention_notes text,
  -- Interruptores de configuración
  add column if not exists admin_settings jsonb default '{}'::jsonb,
  add column if not exists updated_at timestamptz;
