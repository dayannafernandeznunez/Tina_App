-- Un solo inicio de sesión para clientas y administradora.
--
-- Todas las personas se registran en Supabase Auth. Al registrarse se crea su
-- fila en `cliente`. Quién es administradora lo dice la tabla `usuario`
-- (ver crear_administradora.sql); quien no está ahí es clienta.

-- La fila de cliente se crea sola cuando alguien se registra, aunque todavía no
-- haya confirmado su correo.
create or replace function public.crear_cliente_al_registrarse()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.cliente (id_auth, nombre, correo, cuenta_registrada)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'nombre', ''), split_part(new.email, '@', 1)),
    new.email,
    true
  )
  on conflict (id_auth) do nothing;
  return new;
end;
$$;

drop trigger if exists al_registrarse on auth.users;
create trigger al_registrarse
  after insert on auth.users
  for each row execute function public.crear_cliente_al_registrarse();

-- Cada clienta ve y cambia solo su propia fila. (La administradora ya ve todas:
-- ver la política "admin gestiona clientes".)
create policy "ver mi cliente" on public.cliente
  for select to authenticated
  using (id_auth = auth.uid());

-- Para cuentas que se crearon antes de este script (por ejemplo, la tuya): la
-- app crea la fila la primera vez que entran.
create policy "crear mi cliente" on public.cliente
  for insert to authenticated
  with check (id_auth = auth.uid() and cuenta_registrada);

create policy "cambiar mi cliente" on public.cliente
  for update to authenticated
  using (id_auth = auth.uid())
  with check (id_auth = auth.uid());

-- Tu cuenta de administradora, si ya existía, también necesita su fila de cliente.
insert into public.cliente (id_auth, nombre, correo, cuenta_registrada)
select u.id,
       coalesce(nullif(u.raw_user_meta_data ->> 'nombre', ''), split_part(u.email, '@', 1)),
       u.email,
       true
from auth.users u
on conflict (id_auth) do nothing;
