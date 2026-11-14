-- Convierte tu cuenta en administradora de Tina.
--
-- Antes: en Supabase, Authentication > Users > Add user, crea tu cuenta con tu
-- correo y una contraseña, y márcala como confirmada ("Auto Confirm User").
--
-- Después: cambia TU_CORREO_AQUI por ese mismo correo y ejecuta este archivo en
-- el SQL Editor. Solo hay que hacerlo una vez.

insert into public.usuario (id_auth, nombre, correo, rol)
select id, 'Administradora Tina', email, 'administradora'
from auth.users
where email = 'TU_CORREO_AQUI'
on conflict (id_auth) do update set rol = 'administradora';

-- Debe devolver una fila con tu correo y el rol "administradora".
select id_usuario, correo, rol from public.usuario;
