-- ═══════════════════════════════════════
-- 🧨 LIMPIEZA TOTAL
-- ═══════════════════════════════════════

drop view if exists public.tableros_conteo_items cascade;

drop table if exists public.cartas_borradas cascade;
drop table if exists public.cartas cascade;
drop table if exists public.sugerencias cascade;
drop table if exists public.item_adjuntos cascade;
drop table if exists public.items cascade;
drop table if exists public.tableros cascade;
drop table if exists public.perfiles cascade;
drop table if exists public.encuentros cascade;
drop table if exists public.notas cascade;

drop type if exists public.carta_alcance cascade;
drop type if exists public.sugerencia_estado cascade;
drop type if exists public.item_tipo cascade;
drop type if exists public.item_estado cascade;

drop function if exists public.touch_items_updated_at cascade;
drop function if exists public.tableros_set_depth cascade;
drop function if exists public.handle_new_user cascade;

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- ═══════════════════════════════════════
-- 👤 PERFILES
-- ═══════════════════════════════════════

create table public.perfiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique,
  nombre_completo text,
  bio text,
  avatar_url text,
  intereses text[],
  actualizado_en timestamptz default now()
);

alter table perfiles enable row level security;

create policy perfiles_select on perfiles for select using (true);
create policy perfiles_insert on perfiles
  for insert
  with check (auth.uid() = id);
create policy perfiles_update on perfiles
  for update
  using (auth.uid() = id);

-- 🔥 AUTO CREAR PERFIL AL REGISTRARSE (a prueba de duplicados)
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.perfiles (id)
  values (new.id)
  on conflict (id) do nothing;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ═══════════════════════════════════════
-- 🗂️ ENUMS
-- ═══════════════════════════════════════

create type public.item_tipo as enum ('texto','link','imagen','audio','video','archivo');
create type public.item_estado as enum ('inbox','organizado','archivado');
create type public.carta_alcance as enum ('directa','cercanos');
create type public.sugerencia_estado as enum ('pendiente','aceptada','rechazada');

-- ═══════════════════════════════════════
-- 📌 TABLEROS
-- ═══════════════════════════════════════

create table public.tableros (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references perfiles(id) on delete cascade,
  parent_id uuid references tableros(id) on delete cascade,
  titulo text not null,
  descripcion text,
  imagen_portada text,
  is_public boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  depth int
);

alter table tableros enable row level security;

create policy tableros_select_own on tableros for select using (user_id = auth.uid());
create policy tableros_select_public on tableros for select using (is_public = true);
create policy tableros_insert on tableros for insert with check (user_id = auth.uid());
create policy tableros_update on tableros for update using (user_id = auth.uid());
create policy tableros_delete on tableros for delete using (user_id = auth.uid());

create function public.tableros_set_depth()
returns trigger language plpgsql as $$
declare parent_depth int;
begin
  if new.parent_id is null then
    new.depth = 1;
  else
    select depth into parent_depth from tableros where id = new.parent_id;
    new.depth = coalesce(parent_depth,0) + 1;
  end if;
  return new;
end$$;

create trigger trg_tableros_set_depth
before insert or update of parent_id on tableros
for each row execute function public.tableros_set_depth();

-- ═══════════════════════════════════════
-- 🧠 ITEMS (INBOX)
-- ═══════════════════════════════════════

create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references perfiles(id) on delete cascade,
  tablero_id uuid references tableros(id) on delete cascade,
  tipo item_tipo not null,
  estado item_estado default 'inbox',
  titulo text,
  contenido text,
  metadatos jsonb default '{}',
  tags text[],
  is_public boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create function public.touch_items_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end$$;

create trigger trg_touch_items
before update on items
for each row execute function public.touch_items_updated_at();

alter table items enable row level security;

create policy items_select on items for select using (auth.uid() = user_id or is_public);
create policy items_insert on items for insert with check (auth.uid() = user_id);
create policy items_update on items for update using (auth.uid() = user_id);
create policy items_delete on items for delete using (auth.uid() = user_id);

-- ═══════════════════════════════════════
-- 📎 ADJUNTOS
-- ═══════════════════════════════════════

create table public.item_adjuntos (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references items on delete cascade,
  storage_path text,
  created_at timestamptz default now()
);

alter table item_adjuntos enable row level security;

create policy adjuntos_select on item_adjuntos
for select using (
  exists(select 1 from items i where i.id = item_id and i.user_id = auth.uid())
);

create policy adjuntos_insert on item_adjuntos
for insert with check (
  exists(select 1 from items i where i.id = item_id and i.user_id = auth.uid())
);

-- ═══════════════════════════════════════
-- 💌 CARTAS
-- ═══════════════════════════════════════

create table public.cartas (
  id uuid primary key default gen_random_uuid(),
  autor_id uuid references auth.users on delete cascade,
  target_user_id uuid references auth.users on delete cascade,
  alcance carta_alcance default 'cercanos',
  contenido text,
  created_at timestamptz default now()
);

create table public.cartas_borradas (
  user_id uuid references auth.users on delete cascade,
  carta_id uuid references cartas on delete cascade,
  primary key(user_id,carta_id)
);

alter table cartas enable row level security;

create policy cartas_select on cartas
for select using (
  target_user_id = auth.uid()
  or (target_user_id is null and alcance = 'cercanos')
);

create policy cartas_insert on cartas
for insert with check (autor_id = auth.uid());

-- ═══════════════════════════════════════
-- 💡 SUGERENCIAS
-- ═══════════════════════════════════════

create table public.sugerencias (
  id uuid primary key default gen_random_uuid(),
  autor_id uuid references auth.users on delete cascade,
  target_user_id uuid references auth.users on delete cascade,
  target_tablero_id uuid references tableros(id) on delete set null,
  estado sugerencia_estado default 'pendiente',
  titulo text,
  contenido text,
  tipo item_tipo,
  raw_data jsonb,
  created_at timestamptz default now()
);

alter table sugerencias enable row level security;

create policy sugerencias_select on sugerencias
for select using (auth.uid() = autor_id or auth.uid() = target_user_id);

create policy sugerencias_insert on sugerencias
for insert with check (auth.uid() = autor_id);

create policy sugerencias_update on sugerencias
for update using (auth.uid() = target_user_id);

-- ═══════════════════════════════════════
-- 🤝 ENCUENTROS
-- ═══════════════════════════════════════

create table public.encuentros (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references perfiles(id) on delete cascade,
  usuario_encontrado_id uuid references perfiles(id) on delete cascade,
  match_score int,
  visto_en timestamptz default now(),
  constraint encuentros_unique_users unique (user_id, usuario_encontrado_id)
);

alter table encuentros enable row level security;

create policy encuentros_select on encuentros
for select using (auth.uid() = user_id);

create policy encuentros_insert on encuentros
for insert with check (auth.uid() = user_id);

create policy encuentros_delete on encuentros
for delete using (auth.uid() = user_id);

-- ═══════════════════════════════════════
-- 📝 NOTAS
-- ═══════════════════════════════════════

create table public.notas (
  id uuid primary key default gen_random_uuid(),
  contenido text,
  user_id uuid default auth.uid() references auth.users
);

alter table notas enable row level security;

create policy notas_select on notas for select using (auth.uid() = user_id);
create policy notas_insert on notas for insert with check (auth.uid() = user_id);
create policy notas_delete on notas for delete using (auth.uid() = user_id);

-- ═══════════════════════════════════════
-- 📦 STORAGE (SAFE)
-- ═══════════════════════════════════════

insert into storage.buckets (id,name,public)
values ('inbox-uploads','inbox-uploads',false)
on conflict do nothing;



ALTER TABLE public.tableros ADD COLUMN ai_summary TEXT;
ALTER TABLE public.items ADD COLUMN ai_summary TEXT;