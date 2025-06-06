PGDMP                      }            hayat    17.5    17.5 Z    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    16400    hayat    DATABASE     y   CREATE DATABASE hayat WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE hayat;
                     postgres    false            �           0    0    DATABASE hayat    ACL     �   REVOKE CONNECT,TEMPORARY ON DATABASE hayat FROM PUBLIC;
GRANT ALL ON DATABASE hayat TO PUBLIC;
GRANT ALL ON DATABASE hayat TO hayat;
                        postgres    false    5039                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                     pg_database_owner    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                        pg_database_owner    false    5                       1255    16610 8   add_token(integer, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.add_token(IN p_users_id integer, IN p_auth_token character varying, IN p_refresh_token character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
begin
	
	if p_users_id is null then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;
	
	if p_auth_token is null or coalesce(trim(p_auth_token),'')='' then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (ACCESS_TOKEN)';
		return;
	end if;

	if p_refresh_token is null or coalesce(trim(p_refresh_token),'')='' then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (REFRESH_TOKEN)';
		return;
	end if;

	insert into user_tokens (id, users_id, auth_token, refresh_token, expires_in, refresh_token_expires)
	values (nextval('user_tokens_seq'), p_users_id, p_auth_token, p_refresh_token, now()+interval '1 day', now()+interval '1 week');

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
end;$$;
 �   DROP PROCEDURE public.add_token(IN p_users_id integer, IN p_auth_token character varying, IN p_refresh_token character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            "           1255    16549    balance_align(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.balance_align(IN p_users_id integer, OUT p_result integer)
    LANGUAGE plpgsql
    AS $$declare
	l_all_amount double precision;
	l_changed_rows integer;
	l_user users;
begin
	if p_users_id is null then
		p_result:=4;
		--p_result_msg:='Kerakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;

	select * into l_user from users where id=p_users_id and is_deleted=0;

	if not found then
		p_result:=11;
		--p_result_msg:='Foydalanuvchi aniqlanmadi';
		return;
	end if;
	
	select coalesce (sum (amount), 0)
                  into l_all_amount
                  from user_transactions
                 where users_id = p_users_id and status = 1;

	update users set balance=l_all_amount where id=p_users_id;

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		--p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		return;
	end if;
end;$$;
 R   DROP PROCEDURE public.balance_align(IN p_users_id integer, OUT p_result integer);
       public               postgres    false    5            #           1255    16620 >   before_perform_transaction(integer, integer, double precision) 	   PROCEDURE     �  CREATE PROCEDURE public.before_perform_transaction(IN p_users_id integer, IN p_transaction_types_id integer, IN p_amount double precision, OUT p_otp_session character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
	l_user users;
	l_transaction_type user_transaction_types;
	l_actual_balance double precision;
	--
	l_result integer;
	l_result_msg varchar(200);
	l_try_cnt integer;
begin
	if p_users_id is null then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;


	if p_transaction_types_id is null then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri kiritilmagan (TRANSACTION_TYPE)';
		return;
	end if;

	if p_amount is null then
		p_result:=12;
		p_result_msg:='Summa noto`g`ri kiritilgan';
		return;
	end if;

	if p_amount <=0 then
		p_result:=12;
		p_result_msg:='Summa noto`g`ri kiritilgan';
		return;
	end if;

	select * into l_user from users where id=p_users_id and is_deleted=0;

	if not found then
		p_result:=11;
		p_result_msg:='Foydalanuvchi aniqlanmadi';
		return;
	end if;

	select * into l_transaction_type from user_transaction_types
	where id=p_transaction_types_id;

	if not found then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri topilmadi (TRANSACTION_TYPE)';
		return;
	end if;

	if l_transaction_type.is_debit!=1 then
		if check_balance(p_users_id, p_amount)!=1 then
			p_result:=14;
			p_result_msg:='Hisobingizda yetarli mablag` mavjud emas';
			return;
		end if;
	end if;

	call create_otp_session(l_user.phone, p_otp_session, l_result, l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
end;$$;
 �   DROP PROCEDURE public.before_perform_transaction(IN p_users_id integer, IN p_transaction_types_id integer, IN p_amount double precision, OUT p_otp_session character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            �            1255    16544 (   check_balance(integer, double precision)    FUNCTION     D  CREATE FUNCTION public.check_balance(p_users_id integer, p_amount double precision) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
   l_balance double precision;
begin
   
   select get_balance(p_users_id)
   into l_balance;
   
   if l_balance>=p_amount then
   	return 1;
   else
   	return 0;
   end if;
end;
$$;
 S   DROP FUNCTION public.check_balance(p_users_id integer, p_amount double precision);
       public               postgres    false    5                       1255    16613 &   check_by_auth_token(character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.check_by_auth_token(IN p_auth_token character varying, OUT p_users_id integer)
    LANGUAGE plpgsql
    AS $$declare
	l_token user_tokens;
begin
	select * into l_token from user_tokens 
	where auth_token=p_auth_token and is_deleted=0;

	if not found then
		return;
	end if;

	if l_token.expires_in<localtimestamp then
		return;
	end if;
	p_users_id=l_token.users_id;
end;$$;
 f   DROP PROCEDURE public.check_by_auth_token(IN p_auth_token character varying, OUT p_users_id integer);
       public               postgres    false    5                        1255    16614 2   check_by_refresh_token(character varying, integer) 	   PROCEDURE     �  CREATE PROCEDURE public.check_by_refresh_token(IN p_refresh_token character varying, IN p_invoke integer, OUT p_users_id integer)
    LANGUAGE plpgsql
    AS $$declare
	l_token user_tokens;
	l_changed_rows integer;
begin
	select * into l_token from user_tokens 
	where refresh_token=p_refresh_token and is_deleted=0;

	if not found then
		return;
	end if;

	if l_token.refresh_token_expires<localtimestamp then
		return;
	end if;
	
	if p_invoke=1 then
		update user_tokens set is_deleted=1 where id=l_token.id;

		GET DIAGNOSTICS l_changed_rows = ROW_COUNT;
	
		if l_changed_rows=0 then
			rollback;
			return;
		end if;
	end if;

	p_users_id=l_token.users_id;
end;$$;
 �   DROP PROCEDURE public.check_by_refresh_token(IN p_refresh_token character varying, IN p_invoke integer, OUT p_users_id integer);
       public               postgres    false    5            %           1255    16607 7   check_otp_session(character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.check_otp_session(IN p_session_id character varying, IN p_code character varying, OUT p_try_cnt integer, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_otp_session otp_sessions;
	l_changed_rows integer;
begin
	if p_session_id is null or coalesce(trim(p_session_id), '')='' then
		p_result:=4;
		p_result_msg:='Kerakli ma`lumotlardan biri mavjud emas (SESSION_ID)';
		return;
	end if;

	if p_code is null or coalesce(trim(p_code), '')='' then
		p_result:=5;
		p_result_msg:='Tasdiqlash kodini kiriting';
		return;
	end if;
	
	select * into l_otp_session from otp_sessions 
	where session_id=p_session_id;

	if not found then
		p_result:=6;
		p_result_msg:='Tasdiqlash kodini to`g`ri kiriting';
		return;
	end if;

	if l_otp_session.is_confirmed=1 then
		p_result:=7;
		p_result_msg:='Tasdiqlash kodini qayta oling';
		return;
	end if;

	if l_otp_session.try_cnt>=5 then
		p_result:=8;
		p_result_msg:='Tasdiqlash kodini kiritish limiti tugadi';
		return;
	end if;

	if l_otp_session.expires_in < LOCALTIMESTAMP then
		p_result:=9;
		p_result_msg:='Tasdiqlash kodining amal qilish vaqti tugadi. Qayta oling';
		return;
	end if;

	if l_otp_session.code!=p_code then
		p_result:=6;
		p_result_msg:='Tasdiqlash kodini to`g`ri kiriting';
		p_try_cnt:=l_otp_session.try_cnt+1;
		update otp_sessions set try_cnt=l_otp_session.try_cnt+1 where id=l_otp_session.id;
		return;
	end if;

	update otp_sessions set is_confirmed=1, confirmed_time=now() where id=l_otp_session.id;

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;
	
	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		return;
	end if;
	
	p_result:=0;
	p_result_msg:='Success';
end;$$;
 �   DROP PROCEDURE public.check_otp_session(IN p_session_id character varying, IN p_code character varying, OUT p_try_cnt integer, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            �            1255    16557 %   check_phone_number(character varying)    FUNCTION     z  CREATE FUNCTION public.check_phone_number(p_phone_number character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$declare
	l_code varchar(2);
	l_code_exists integer;
begin
	if p_phone_number is null or coalesce(TRIM(p_phone_number), '') = '' then
		--Telefon raqam kiritilmagan
		return -1;
	end if;

	l_code:=substring(p_phone_number, 1, 2);
	
	if l_code is null then
		--Telefon raqam xato kiritilgan
		return 0;
	end if;

	select count(*) into l_code_exists from phone_codes 
	where phone_code=l_code and is_deleted=0;
	
	if l_code_exists != 1 then
		--Telefon raqam xato kiritilgan
		return 0;
	end if;
	return 1;
end;$$;
 K   DROP FUNCTION public.check_phone_number(p_phone_number character varying);
       public               postgres    false    5                       1255    16605 %   create_otp_session(character varying) 	   PROCEDURE       CREATE PROCEDURE public.create_otp_session(IN p_phone character varying, OUT p_session_id character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
	l_correct_phone integer;
	l_code varchar(6);
	l_session_id varchar(100);
	l_notification varchar(200):='Sizning tasdiqlash kodingiz: #code#. Ushbu kodni xech kimga bermang. Uni faqatgina firibgarlar so`raydi!!!';
	--
	l_result integer;
	l_result_msg varchar(200);
begin
	if p_phone is null or coalesce(trim(p_phone),'')='' then
		p_result:=1;
		p_result_msg:='Telefon raqam kiritilmagan';
		return;
	end if;

	l_correct_phone:=check_phone_number(p_phone);

	if l_correct_phone!=1 then
		p_result:=3;
		p_result_msg:='Telefon raqamni to`g`ri kiriting';
		return;
	end if;

	l_code:=get_random_code(111111, 999999);
	l_session_id:=sha1(l_code||p_phone||now());

	insert into otp_sessions (id, session_id, code, expires_in)
	values (nextval('otp_sessions_seq'), l_session_id, l_code, now()+interval '3 minute');

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;
	
	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		return;
	end if;

	l_notification:=replace(l_notification, '#code#', l_code);

	call send_notification(p_phone,l_notification,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
	p_session_id=l_session_id;
end;$$;
 �   DROP PROCEDURE public.create_otp_session(IN p_phone character varying, OUT p_session_id character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            &           1255    16612 �   create_user(character varying, character varying, character varying, character varying, character varying, character varying, character varying) 	   PROCEDURE     �
  CREATE PROCEDURE public.create_user(IN p_fio character varying, IN p_phone character varying, IN p_email character varying, IN p_auth_token character varying, IN p_refresh_token character varying, IN p_session_id character varying, IN p_otp_code character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_new_user_id integer;
	l_changed_rows integer;
	l_correct_phone integer;
	l_notification varchar(200):='Ro`yxatdan o`tganingiz bilan tabriklaymiz';
	--
	l_result integer;
	l_result_msg varchar(200);
	l_try_cnt integer;
begin
	if p_fio is null or coalesce(trim(p_fio),'')='' then
		p_result:=10;
		p_result_msg:='F.I.Sh. kiritilmagan';
		return;
	end if;
	
	if p_phone is null or coalesce(trim(p_phone),'')='' then
		p_result:=1;
		p_result_msg:='Telefon raqam kiritilmagan';
		return;
	end if;

	if p_auth_token is null or coalesce(trim(p_auth_token),'')='' then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (ACCESS_TOKEN)';
		return;
	end if;

	if p_refresh_token is null or coalesce(trim(p_refresh_token),'')='' then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (REFRESH_TOKEN)';
		return;
	end if;

	if p_session_id is null or coalesce(trim(p_session_id),'')='' then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (OTP_SESSION)';
		return;
	end if;

	if p_otp_code is null or coalesce(trim(p_otp_code),'')='' then
		p_result:=5;
		p_result_msg:='Tasdiqlash kodi kiritilmagan';
		return;
	end if;

	l_correct_phone:=check_phone_number(p_phone);

	if l_correct_phone!=1 then
		p_result:=3;
		p_result_msg:='Telefon raqamni to`g`ri kiriting';
		return;
	end if;

	call check_otp_session(p_session_id,p_otp_code,l_try_cnt,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	insert into users (id, user_statuses_id, fio, phone, email)
	values (nextval('users_seq'), 1, p_fio, p_phone, p_email)
	returning id into l_new_user_id;

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		rollback;
		return;
	end if;

	l_result:=null;
	l_result_msg:=null;

	call add_token (l_new_user_id, p_auth_token, p_refresh_token, l_result, l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	call send_notification(p_phone,l_notification,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
end;$$;
 B  DROP PROCEDURE public.create_user(IN p_fio character varying, IN p_phone character varying, IN p_email character varying, IN p_auth_token character varying, IN p_refresh_token character varying, IN p_session_id character varying, IN p_otp_code character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            !           1255    16616    delete_user(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.delete_user(IN p_users_id integer, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
	l_user users;
	l_notification varchar(200):='Profilingiz so`rovingizga ko`ra o`chirib yuborildi';
	l_transactions_cnt integer;
	--
	l_result integer;
	l_result_msg varchar(200);
begin
	if p_users_id is null then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;

	select * into l_user from users where id=p_users_id and is_deleted=0;

	if not found then
		p_result:=11;
		p_result_msg:='Foydalanuvchi aniqlanmadi';
		return;
	end if;

	select 
	count(*) into l_transactions_cnt 
	from user_transactions 
	where users_id=p_users_id;

	if l_transactions_cnt!=0 then
		p_result:=12;
		p_result_msg:='Shaxsiy hisbraqam bilan amaliyotlar mavjudligi sababli profilni o`chirib bo`lmaydi';
		return;
	end if;

	update users set is_deleted=1 where id=p_users_id;

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		rollback;
		return;
	end if;

	call send_notification(l_user.phone,l_notification,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
end;$$;
 t   DROP PROCEDURE public.delete_user(IN p_users_id integer, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            �            1255    16538    get_balance(integer)    FUNCTION     �   CREATE FUNCTION public.get_balance(p_users_id integer) RETURNS double precision
    LANGUAGE sql
    AS $$select balance from users where id=p_users_id;$$;
 6   DROP FUNCTION public.get_balance(p_users_id integer);
       public               postgres    false    5            �            1255    16547 !   get_random_code(integer, integer)    FUNCTION       CREATE FUNCTION public.get_random_code(p_min integer, p_max integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$declare
l_random_code text;
begin
--select floor(random() * (p_max-p_min + 1) + p_min) into l_random_code;
l_random_code:='123456';
return l_random_code;
end;$$;
 D   DROP FUNCTION public.get_random_code(p_min integer, p_max integer);
       public               postgres    false    5            $           1255    16618 p   perform_transaction(integer, integer, double precision, character varying, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.perform_transaction(IN p_users_id integer, IN p_transaction_types_id integer, IN p_amount double precision, IN p_detail character varying, IN p_otp_session character varying, IN p_otp_code character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
	l_user users;
	l_transaction_type user_transaction_types;
	l_actual_balance double precision;
	l_amount double precision;
	l_saldo_end double precision;
	l_notification varchar(200):='Hisobingiz #amount# so`mga o`zgartirildi. Xozirgi mavjud mablag: #balance# so`m';
	--
	l_result integer;
	l_result_msg varchar(200);
	l_try_cnt integer;
begin
	if p_users_id is null then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;

	if p_transaction_types_id is null then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri kiritilmagan (TRANSACTION_TYPE)';
		return;
	end if;

	if p_amount is null then
		p_result:=12;
		p_result_msg:='Summa noto`g`ri kiritilgan';
		return;
	end if;

	if p_amount <=0 then
		p_result:=12;
		p_result_msg:='Summa noto`g`ri kiritilgan';
		return;
	end if;

	if p_detail is null or coalesce(trim(p_detail),'')='' then
		p_result:=13;
		p_result_msg:='To`lov maqsadini kiriting';
		return;
	end if;

	if p_otp_session is null or coalesce(trim(p_otp_session),'')='' then
		p_result:=4;
		p_result_msg:='Kerakli ma`lumotlardan biri mavjud emas (SESSION_ID)';
		return;
	end if;

	if p_otp_code is null or coalesce(trim(p_otp_code), '')='' then
		p_result:=5;
		p_result_msg:='Tasdiqlash kodini kiriting';
		return;
	end if;

	select * into l_user from users where id=p_users_id and is_deleted=0;

	if not found then
		p_result:=11;
		p_result_msg:='Foydalanuvchi aniqlanmadi';
		return;
	end if;

	select * into l_transaction_type from user_transaction_types
	where id=p_transaction_types_id;

	if not found then
		p_result:=4;
		p_result_msg:='Kerakli maydonlardan biri topilmadi (TRANSACTION_TYPE)';
		return;
	end if;

	if l_transaction_type.is_debit!=1 then
		if check_balance(p_users_id, p_amount)!=1 then
			p_result:=14;
			p_result_msg:='Hisobingizda yetarli mablag` mavjud emas';
			return;
		end if;
	end if;

	call check_otp_session(p_otp_session,p_otp_code,l_try_cnt,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	l_actual_balance:=coalesce(get_balance(p_users_id), 0);
	l_amount:=(case when l_transaction_type.is_debit!=1 then -1 else 1 end)*p_amount;
	l_saldo_end:=l_actual_balance+l_amount;

	insert into user_transactions (id, users_id, user_transaction_types_id, saldo_start, amount, saldo_end, payment_details)
	values (nextval('user_transactions_seq'), p_users_id, p_transaction_types_id, l_actual_balance, l_amount, l_saldo_end, l_transaction_type.name_uz);

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		rollback;
		return;
	end if;

	call balance_align(p_users_id, l_result);

	l_actual_balance:=coalesce(get_balance(p_users_id), 0);

	l_notification:=replace(l_notification, '#amount#', ''||p_amount);
	l_notification:=replace(l_notification, '#balance#', ''||l_actual_balance);

	call send_notification(l_user.phone,l_notification,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';	
end;$$;
 !  DROP PROCEDURE public.perform_transaction(IN p_users_id integer, IN p_transaction_types_id integer, IN p_amount double precision, IN p_detail character varying, IN p_otp_session character varying, IN p_otp_code character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5                       1255    16562 7   send_notification(character varying, character varying) 	   PROCEDURE     9  CREATE PROCEDURE public.send_notification(IN p_recipient character varying, IN p_content character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_code_exists integer;
	l_changed_rows integer;
begin
	if p_recipient is null or coalesce(TRIM(p_recipient), '') = '' then
		p_result:=1;
		p_result_msg:='Telefon raqam kiritilmagan';
		return;
	end if;

	if p_content is null or coalesce(TRIM(p_content), '') = '' then
		p_result:=2;
		p_result_msg:='Xabar matni kiritilmagan';
		return;
	end if;
	
	l_code_exists:=check_phone_number(p_recipient);

	if l_code_exists!=1 then
		p_result:=3;
		p_result_msg:='Telefon raqamni to`g`ri kiriting';
		return;
	end if;

	insert into notifications (id, recipient, content)
	values (nextval('notifications_seq'), p_recipient, p_content);

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;
	
	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		return;
	end if;
	
	p_result:=0;
	p_result_msg:='Success';
end;$$;
 �   DROP PROCEDURE public.send_notification(IN p_recipient character varying, IN p_content character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5                       1255    16602    sha1(character varying)    FUNCTION     �   CREATE FUNCTION public.sha1(p_text character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$declare
begin 
	return encode(digest(p_text, 'sha1'), 'hex');
end;$$;
 5   DROP FUNCTION public.sha1(p_text character varying);
       public               postgres    false    5                       1255    16615 :   update_user(integer, character varying, character varying) 	   PROCEDURE     ?  CREATE PROCEDURE public.update_user(IN p_users_id integer, IN p_fio character varying, IN p_email character varying, OUT p_result integer, OUT p_result_msg character varying)
    LANGUAGE plpgsql
    AS $$declare
	l_changed_rows integer;
	l_user users;
	l_notification varchar(200):='Ma`lumotlaringiz muvofaqqiyatli o`zgartirildi';
	--
	l_result integer;
	l_result_msg varchar(200);
begin
	if p_users_id is null then
		p_result:=4;
		p_result_msg:='Karakli maydonlardan biri kiritilmagan (USER)';
		return;
	end if;

	if p_fio is null or coalesce(trim(p_fio),'')='' then
		p_result:=10;
		p_result_msg:='F.I.Sh. kiritilmagan';
		return;
	end if;

	select * into l_user from users where id=p_users_id and is_deleted=0;

	if not found then
		p_result:=11;
		p_result_msg:='Foydalanuvchi aniqlanmadi';
		return;
	end if;

	update users set fio=p_fio, email=p_email, updated_date=now() where id=p_users_id;

	GET DIAGNOSTICS l_changed_rows = ROW_COUNT;

	if l_changed_rows=0 then
		p_result:=4;
		p_result_msg:='Amalani bajarishda xatolik yuz berdi. Iltimos, keyinroq urinib ko`ring';
		rollback;
		return;
	end if;

	call send_notification(l_user.phone,l_notification,l_result,l_result_msg);

	if l_result!=0 then
		p_result:=l_result;
		p_result_msg:=l_result_msg;
		rollback;
		return;
	end if;

	p_result:=0;
	p_result_msg:='Success';
end;$$;
 �   DROP PROCEDURE public.update_user(IN p_users_id integer, IN p_fio character varying, IN p_email character varying, OUT p_result integer, OUT p_result_msg character varying);
       public               postgres    false    5            �            1259    16505    notifications    TABLE     A  CREATE TABLE public.notifications (
    id integer NOT NULL,
    recipient character varying(9) NOT NULL,
    content character varying(250) NOT NULL,
    created_date timestamp without time zone DEFAULT now(),
    is_sent integer DEFAULT 0,
    sent_time timestamp without time zone,
    is_deleted integer DEFAULT 0
);
 !   DROP TABLE public.notifications;
       public         heap r       postgres    false    5            �           0    0    TABLE notifications    ACL     2   GRANT ALL ON TABLE public.notifications TO hayat;
          public               postgres    false    223            �            1259    16556    notifications_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999
    CACHE 1;
 (   DROP SEQUENCE public.notifications_seq;
       public               postgres    false    5    223            �           0    0    notifications_seq    SEQUENCE OWNED BY     J   ALTER SEQUENCE public.notifications_seq OWNED BY public.notifications.id;
          public               postgres    false    226            �           0    0    SEQUENCE notifications_seq    ACL     9   GRANT ALL ON SEQUENCE public.notifications_seq TO hayat;
          public               postgres    false    226            �            1259    16489    otp_sessions    TABLE     `  CREATE TABLE public.otp_sessions (
    id integer NOT NULL,
    session_id character varying(100),
    code character varying(15),
    created_date timestamp without time zone DEFAULT now(),
    try_cnt integer DEFAULT 0,
    expires_in timestamp without time zone,
    is_confirmed integer DEFAULT 0,
    confirmed_time timestamp without time zone
);
     DROP TABLE public.otp_sessions;
       public         heap r       postgres    false    5            �           0    0    TABLE otp_sessions    ACL     1   GRANT ALL ON TABLE public.otp_sessions TO hayat;
          public               postgres    false    222            �            1259    16563    otp_sessions_seq    SEQUENCE     }   CREATE SEQUENCE public.otp_sessions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;
 '   DROP SEQUENCE public.otp_sessions_seq;
       public               postgres    false    222    5            �           0    0    otp_sessions_seq    SEQUENCE OWNED BY     H   ALTER SEQUENCE public.otp_sessions_seq OWNED BY public.otp_sessions.id;
          public               postgres    false    227            �           0    0    SEQUENCE otp_sessions_seq    ACL     8   GRANT ALL ON SEQUENCE public.otp_sessions_seq TO hayat;
          public               postgres    false    227            �            1259    16550    phone_codes    TABLE     �   CREATE TABLE public.phone_codes (
    id integer NOT NULL,
    company_name character varying(100),
    phone_code character varying(2) NOT NULL,
    is_deleted integer DEFAULT 0 NOT NULL
);
    DROP TABLE public.phone_codes;
       public         heap r       postgres    false    5            �           0    0    TABLE phone_codes    ACL     0   GRANT ALL ON TABLE public.phone_codes TO hayat;
          public               postgres    false    225            �            1259    16401    user_statuses    TABLE     �   CREATE TABLE public.user_statuses (
    id integer NOT NULL,
    name_uz character varying(100),
    name_ru character varying(100),
    ordering integer,
    is_deleted integer DEFAULT 0
);
 !   DROP TABLE public.user_statuses;
       public         heap r       postgres    false    5            �           0    0    TABLE user_statuses    ACL     2   GRANT ALL ON TABLE public.user_statuses TO hayat;
          public               postgres    false    218            �            1259    16474    user_tokens    TABLE     e  CREATE TABLE public.user_tokens (
    id integer NOT NULL,
    users_id integer,
    auth_token character varying(300),
    refresh_token character varying(150),
    expires_in timestamp without time zone,
    created_date timestamp without time zone DEFAULT now(),
    is_deleted integer DEFAULT 0,
    refresh_token_expires timestamp without time zone
);
    DROP TABLE public.user_tokens;
       public         heap r       postgres    false    5            �           0    0    TABLE user_tokens    ACL     0   GRANT ALL ON TABLE public.user_tokens TO hayat;
          public               postgres    false    221            �            1259    16609    user_tokens_seq    SEQUENCE     �   CREATE SEQUENCE public.user_tokens_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 9999999999
    CACHE 1;
 &   DROP SEQUENCE public.user_tokens_seq;
       public               postgres    false    5    221            �           0    0    user_tokens_seq    SEQUENCE OWNED BY     F   ALTER SEQUENCE public.user_tokens_seq OWNED BY public.user_tokens.id;
          public               postgres    false    229            �           0    0    SEQUENCE user_tokens_seq    ACL     7   GRANT ALL ON SEQUENCE public.user_tokens_seq TO hayat;
          public               postgres    false    229            �            1259    16451    user_transaction_types    TABLE     �   CREATE TABLE public.user_transaction_types (
    id integer NOT NULL,
    name_uz character varying(200),
    name_ru character varying(200),
    ordering integer,
    is_debit integer DEFAULT 1
);
 *   DROP TABLE public.user_transaction_types;
       public         heap r       postgres    false    5            �           0    0 &   COLUMN user_transaction_types.is_debit    COMMENT     P   COMMENT ON COLUMN public.user_transaction_types.is_debit IS '1-kirim,0-chiqim';
          public               postgres    false    219            �           0    0    TABLE user_transaction_types    ACL     ;   GRANT ALL ON TABLE public.user_transaction_types TO hayat;
          public               postgres    false    219            �            1259    16514    user_transactions    TABLE     z  CREATE TABLE public.user_transactions (
    id integer NOT NULL,
    users_id integer,
    user_transaction_types_id integer,
    saldo_start double precision DEFAULT 0,
    amount double precision DEFAULT 0,
    saldo_end double precision DEFAULT 0,
    created_date timestamp without time zone DEFAULT now(),
    status integer DEFAULT 1,
    payment_details text NOT NULL
);
 %   DROP TABLE public.user_transactions;
       public         heap r       postgres    false    5            �           0    0    TABLE user_transactions    ACL     6   GRANT ALL ON TABLE public.user_transactions TO hayat;
          public               postgres    false    224            �            1259    16617    user_transactions_seq    SEQUENCE     �   CREATE SEQUENCE public.user_transactions_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 9999999
    CACHE 1;
 ,   DROP SEQUENCE public.user_transactions_seq;
       public               postgres    false    5    224            �           0    0    user_transactions_seq    SEQUENCE OWNED BY     R   ALTER SEQUENCE public.user_transactions_seq OWNED BY public.user_transactions.id;
          public               postgres    false    230            �           0    0    SEQUENCE user_transactions_seq    ACL     =   GRANT ALL ON SEQUENCE public.user_transactions_seq TO hayat;
          public               postgres    false    230            �            1259    16456    users    TABLE     �  CREATE TABLE public.users (
    id integer NOT NULL,
    user_statuses_id integer NOT NULL,
    fio character varying(250),
    phone character varying(9),
    email character varying(150),
    registered_date timestamp without time zone DEFAULT now(),
    updated_date timestamp without time zone,
    balance numeric DEFAULT 0,
    is_deleted integer DEFAULT 0,
    password_enc character varying(100)
);
    DROP TABLE public.users;
       public         heap r       postgres    false    5            �           0    0    TABLE users    ACL     *   GRANT ALL ON TABLE public.users TO hayat;
          public               postgres    false    220            �            1259    16608 	   users_seq    SEQUENCE     w   CREATE SEQUENCE public.users_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 9999999
    CACHE 1;
     DROP SEQUENCE public.users_seq;
       public               postgres    false    5    220            �           0    0 	   users_seq    SEQUENCE OWNED BY     :   ALTER SEQUENCE public.users_seq OWNED BY public.users.id;
          public               postgres    false    228            �           0    0    SEQUENCE users_seq    ACL     1   GRANT ALL ON SEQUENCE public.users_seq TO hayat;
          public               postgres    false    228            �          0    16505    notifications 
   TABLE DATA                 public               postgres    false    223   �       �          0    16489    otp_sessions 
   TABLE DATA                 public               postgres    false    222   Z�       �          0    16550    phone_codes 
   TABLE DATA                 public               postgres    false    225   ��       �          0    16401    user_statuses 
   TABLE DATA                 public               postgres    false    218   ��       �          0    16474    user_tokens 
   TABLE DATA                 public               postgres    false    221   ��       �          0    16451    user_transaction_types 
   TABLE DATA                 public               postgres    false    219   I�       �          0    16514    user_transactions 
   TABLE DATA                 public               postgres    false    224   ��       �          0    16456    users 
   TABLE DATA                 public               postgres    false    220   ��       �           0    0    notifications_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.notifications_seq', 88, true);
          public               postgres    false    226            �           0    0    otp_sessions_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.otp_sessions_seq', 45, true);
          public               postgres    false    227            �           0    0    user_tokens_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.user_tokens_seq', 12, true);
          public               postgres    false    229            �           0    0    user_transactions_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.user_transactions_seq', 28, true);
          public               postgres    false    230            �           0    0 	   users_seq    SEQUENCE SET     8   SELECT pg_catalog.setval('public.users_seq', 10, true);
          public               postgres    false    228                       2606    16512    notifications notifications_pk 
   CONSTRAINT     \   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pk PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pk;
       public                 postgres    false    223            �           2606    16496    otp_sessions otp_sessions_pk 
   CONSTRAINT     Z   ALTER TABLE ONLY public.otp_sessions
    ADD CONSTRAINT otp_sessions_pk PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.otp_sessions DROP CONSTRAINT otp_sessions_pk;
       public                 postgres    false    222                       2606    16555    phone_codes phone_codes_pk 
   CONSTRAINT     X   ALTER TABLE ONLY public.phone_codes
    ADD CONSTRAINT phone_codes_pk PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.phone_codes DROP CONSTRAINT phone_codes_pk;
       public                 postgres    false    225            �           2606    16407    user_statuses user_statuses_pk 
   CONSTRAINT     \   ALTER TABLE ONLY public.user_statuses
    ADD CONSTRAINT user_statuses_pk PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.user_statuses DROP CONSTRAINT user_statuses_pk;
       public                 postgres    false    218            �           2606    16480    user_tokens user_tokens_pk 
   CONSTRAINT     X   ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pk PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.user_tokens DROP CONSTRAINT user_tokens_pk;
       public                 postgres    false    221                       2606    16525 &   user_transactions user_transactions_pk 
   CONSTRAINT     d   ALTER TABLE ONLY public.user_transactions
    ADD CONSTRAINT user_transactions_pk PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.user_transactions DROP CONSTRAINT user_transactions_pk;
       public                 postgres    false    224            �           2606    16455 1   user_transaction_types user_transactions_types_pk 
   CONSTRAINT     o   ALTER TABLE ONLY public.user_transaction_types
    ADD CONSTRAINT user_transactions_types_pk PRIMARY KEY (id);
 [   ALTER TABLE ONLY public.user_transaction_types DROP CONSTRAINT user_transactions_types_pk;
       public                 postgres    false    219            �           2606    16468    users users_pk 
   CONSTRAINT     L   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);
 8   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pk;
       public                 postgres    false    220                        1259    16513    notifications_ix1    INDEX     P   CREATE INDEX notifications_ix1 ON public.notifications USING btree (recipient);
 %   DROP INDEX public.notifications_ix1;
       public                 postgres    false    223            �           1259    16502    otp_sessions_ix1    INDEX     O   CREATE INDEX otp_sessions_ix1 ON public.otp_sessions USING btree (session_id);
 $   DROP INDEX public.otp_sessions_ix1;
       public                 postgres    false    222            �           1259    16503    otp_sessions_ix2    INDEX     I   CREATE INDEX otp_sessions_ix2 ON public.otp_sessions USING btree (code);
 $   DROP INDEX public.otp_sessions_ix2;
       public                 postgres    false    222            �           1259    16486    user_tokens_ix1    INDEX     M   CREATE INDEX user_tokens_ix1 ON public.user_tokens USING btree (auth_token);
 #   DROP INDEX public.user_tokens_ix1;
       public                 postgres    false    221            �           1259    16487    user_tokens_ix2    INDEX     P   CREATE INDEX user_tokens_ix2 ON public.user_tokens USING btree (refresh_token);
 #   DROP INDEX public.user_tokens_ix2;
       public                 postgres    false    221            �           1259    16488    user_tokens_ix3    INDEX     K   CREATE INDEX user_tokens_ix3 ON public.user_tokens USING btree (users_id);
 #   DROP INDEX public.user_tokens_ix3;
       public                 postgres    false    221                       1259    16536    user_transactions_ix1    INDEX     W   CREATE INDEX user_transactions_ix1 ON public.user_transactions USING btree (users_id);
 )   DROP INDEX public.user_transactions_ix1;
       public                 postgres    false    224            �           1259    16465 	   users_ix1    INDEX     G   CREATE INDEX users_ix1 ON public.users USING btree (user_statuses_id);
    DROP INDEX public.users_ix1;
       public                 postgres    false    220            �           1259    16466 	   users_ix2    INDEX     <   CREATE INDEX users_ix2 ON public.users USING btree (phone);
    DROP INDEX public.users_ix2;
       public                 postgres    false    220            	           2606    16481    user_tokens user_tokens_fk1    FK CONSTRAINT     {   ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_fk1 FOREIGN KEY (users_id) REFERENCES public.users(id);
 E   ALTER TABLE ONLY public.user_tokens DROP CONSTRAINT user_tokens_fk1;
       public               postgres    false    4854    220    221            
           2606    16526 '   user_transactions user_transactions_fk1    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_transactions
    ADD CONSTRAINT user_transactions_fk1 FOREIGN KEY (users_id) REFERENCES public.users(id);
 Q   ALTER TABLE ONLY public.user_transactions DROP CONSTRAINT user_transactions_fk1;
       public               postgres    false    220    4854    224                       2606    16531 '   user_transactions user_transactions_fk2    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_transactions
    ADD CONSTRAINT user_transactions_fk2 FOREIGN KEY (user_transaction_types_id) REFERENCES public.user_transaction_types(id);
 Q   ALTER TABLE ONLY public.user_transactions DROP CONSTRAINT user_transactions_fk2;
       public               postgres    false    224    4850    219                       2606    16469    users users_fk1    FK CONSTRAINT        ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_fk1 FOREIGN KEY (user_statuses_id) REFERENCES public.user_statuses(id);
 9   ALTER TABLE ONLY public.users DROP CONSTRAINT users_fk1;
       public               postgres    false    218    4848    220            �   0  x^�\MoG��W�ON ��]������wۋ��C��gM�1I�~}^���!)2i�j���pU��z��j^�~�˯o��������v��/�j����nׯW��~~�l��o�b��h.׫��a��v���9~^4����\�?������|�\��~l���W�~y��`.�)�������v�u��,���z�\�7�n������i�4�D�1�5��A��<����w�^�Ï??{��A�7�l�J�e��a�x�߯��f�m���e���|Z�q��oCֱWͻ���m��ꛯ�K�Js�5���[]�{\��>w��~�5W���]w�e�i����n�?���|�u��ZY��GiǸ�ú5Vf
F�1\�c�GG��xD��8Ʒ�[r*��V<Ƅz�[&�'�ҏR��1.��8-� �C�������Y�@J"jnn���_>�w�n�7��H/;����K+��:�RT��M�i� ��ӟm�W�r�+g������SΕ0��cN����l}�B���4y�Ҡ6GO�R��M˜�`�O$�#���~��Go����3��ój����7�}s�}���͖�5�ط;��,�ɘ�ĭ��b�jjY+muH�L�q�'�N�a�:*���孮�@(9҃��G�Z$<����Z�A�L!�u��f��\N�ֲJƐ���C��n�S:h�j�d��19��u���k��w+$��u�e$�Y�ĕ]7������M�Oq�%d�N�ARf���x����`��)��s�3O9r�T���4��L�{JED�%�b�'g�� e~�5*" 	�W���"#RC�!
����(Nv���/O����q��Ѿ%%�������j�ݶ�"��{�lME#LC�t���7ǠAcؠ��L	Ǟy\R���JN�
�~���9rےQ�zyU��p���8Y(Bl|P asOՀ�yq���"H����N� �E:<��,��'ȇ�q��nEd�o �"!V�"�,��Y�-��<.�����Pa9E��3Qd5� �&e�n%qnm��x.�LĄ+�(7��!�@�P�6�r���G��v*BA��8��f�����#ٳ�2�E��������/. 'F�@qa��9��S�W �6y�!%W��ذ�+fC��y�&���eW�`5x��!��剢+Dq왃��ch�\?��0N�1�$�\!���"�ڡKX^ws�*���DJt�5��@j��r�V�
H���ъ�EW��	T�ʠ�D�|턎��<�GqU�6X(0ެ5zmQ^|sG\�0�L�`gJ�lxR>ZLYH�|�%%xx� Cbq�����X�e3��L���w�+`fU&8�U��o2�VQ�a7/>����&?^k()�Ҟ�[`����'�A93N��Pds5+ڶ�g �'�,����8�<���ݹm!��`���aO����lM!�G�����k�U���ʙ/�9f�q�y1)g����;H��CA.�@I�"erX<0��,���H}&���v�(a�u28tD��ҩ\���g��\��G$,"�O�Q~J���u�aQ^m����z�L.b�I^o����A�ڐ����i6����������&dX�l�*���G�x�.� 0u�t�ϑ�:����#�+�%�����(������p�
C��n�~ F2Y+9�$Cn�2�q��g~��#Eq[ڄUp��}���x��/6��U����g�zz�ss��s:�8&Bf^5a<(���V2�:��G̲�o" ��5��ݙqU���M^��-s�I����(�ˬ��0����l��+K��Ɛ�V=��>��g�"B&['AQ��1��x�D�`"B� �F�A�Ԇ�+�2�@��,��:�G�A�y��:M1,�^$����:Yˑc����\A��:9���X��@pf���� Ex2$� �Ճ
����nn�����!�s��4'5'+���mm��U<9`��07�W{�wx�0B9��S���H,[�a �����A?[�(.b�a<r�qnxD0�s��Df�FHT�����8�?ւ	�b}��(N�0�0&������=�
lN�vȐ�(>{�;�      �   }
  x^�Zˊd���+j'	F��W>�+/�,��&��`͈�1�4����W��ō)ꞎ8q�D���������?�����*�|�ۻ��?}�><�{����s{s�������]����珽=5�|s���?O���7���ߟ��O�oߜ�?<�wo�������������o���?�����|��ޜ��$�U��&����2*�jE��yS�5b�E���ر}��;��Y�Y�&��G<u��ˀ�~���o����g����3�Ff@n���ˀ�  @����U�CL�Yj��8��3!ik�r �ߔ#Ǚ!�s �8l3_k(��(ԉ�0�J�<���rΩW�w ����3ۦ梼*�=��&`���B��	*���#}}���>r���T�!�Kn(�]�Q*�r�^\~�ù-�h�29.��������6%��l8|O��XU�M��L��[W6�w�j��ٙu���b��Vě�d��Hg�-D��G@f��]u�y�cH]B
54�Ci����2��Q.���=e^�x8+��p��'a/��j*Fyh�Ԛr�ѧ��!��:�P4h�C��7���j��e>a
��| >�t�%r�"��#�\s=�:+8w���;��p6����j^���E+j*mf�������F��"�Q$�=�F��5��a�Й��΁��	�7�����&)��� �,%��jm�Wr��e�P��J�*22Ɨ��)T>��&YB��Kd.;�|�A�����0H��̜�`~���PM�IS-�꫋�"o
�{<���㳹͉�r� �����\>!"gbp�-	�TV�.*^�+�()Yւ&m)�����ܩ&�8��tV�,&��xA�{ �܋��t �����^����'�|o*^�z�<��Wf9�xo������r�:��¸x��'h�\��B�+J�滍ѤG�[�:��r�2,TO�9�4�g�-avZd�?��8Hv�,��9�a��V�h�^�Y|H�` h���`�G��V�[21��T/z�h7�dK���Xf�(SO��:wh��`���#�(����K7=;���I0\?_ �g�j��!��_ч�Ŋ
��D��� �28�ĕ_F�M �������
XBqg.�;D#��!9H�|��HEA��t�������z�( �\p���k![����Z�br&��A���d�r,@���Zi���'_c/��^8D_��*���S	��=�.��s�|B����`A���$FIuz"hȩK��Fd��c�����l�p�<:�Z񧛀E9�3�	���Mk%5� �-��I-�W�(�|��M�4��!g�]k�6Q�q!�f ����Y3 ��9#1������̀�duG����ЪtF�j�C�wj�4�s"o�aG,�F1&�<?�r����І��@S��&�/\��_ᆷ���� ��{\,�ڋr�*�zhN�9@�'��]y�R�&R�D�G�]�>���| ���S;����`�,a#p5D����2����P<�O9����eٜ�]�C[��EL�k�d��@���a��9$KS�d.�@T��G������>cs�z?gl��#L��r���
XBw�S���� `�Ԡ��*Eب�6&�b#F��J��3��B�	�}���U��B���f�d�_1�/�
~�2��(�1F�^c��wЗ�������`�5����_�-�x��S֑�9�br�lT3�
�k��kN0�
�@R<,�����"�ޗMI|��`'�c!}���� ��&���j���a��@�fdS �9BC	+XW��l����4{Z�2�����whJ~X��C�����RF:�wR�u���NaI�^]B��*`�&ی�����}!ʘ�1��)hᘥ��\�`7�������*?F.�Ū�U�rNRFޑ��8@�Ⱦ��P/�z,0��uW���G=D�����Ղ��y��Jܷi���*`�,�`�CP��1)sjX9C�!YڀݱD�Qq���x�N�gGc�+���&`�,� �*��!g����+�K-�E������QXI�������WGXc//] �,���΅��P<4�����L[��>�D�>0ZᘣT��':3���wQN;4�Kh�p�ݸ�;B��	J�w>F,H2<ތq*��%q)3	��n��<�	c��R5�����\
���Kc��}�Hp�SU�>�\{+�Zwb�+�δ�L����$AXiչ��̟ϗ��!�-�C��:�.^j�q�u,^sI�й	�X�G6?>$��.�ə���s�����0A�:�"V'iH-󆬂v��`\ �p8�=�GH�ݎA��Ղkqȱ;I��*`���Ñ?F���)�{�MypM�����A�.q;T�G�^M��`���5���
X@�v���ǀf*�C.K��h��&@���Ppj�����;��d��`���U�% ^�U�����̎�|�.�A��2-Ϝ�����{*θ6DB�l����<���>�Zg# ��U�\������:�0�(��B���t ����c�i�y�<�'��1Q�z�u��~>J:�,��W�q��      �     x^��A��0���sS�H�Z��I%��Vm��K�6`Aۂz��eW�ٹ�@`>ޛ�'��orI�Bw;��r��Fe[��ʆ�=w��h�gm��ن�RT�����v.�`�l|�x�ds�<s:��%>r��8]���!)�H���\��#)r�H�7##�}�"��45$��R޽��C��L����a��#>*z[R@Fb�A���/s�e��'�ѳ0��5��
MĢ���OW{�	� ÚHט�PV�k���Ȳ~0U       �   �   x^��v
Q���W((M��L�+-N-�/.I,2�42St�sS�K����R����Ԣ̼t�����ԜԒ�M�0G�P�`Cu���u }a]�.츰��ދ�vŀ���\�4��j�Bjnb1�s/lU������@n�� 	�^�      �   �  x^͘K�����߯`�݉�����#�)�(��&Do((���>_o�d���C�[������P����$Tݜ�[p�W�[�N��d�>eğq�"�lY_����Kj�z�����uq��xci����:\���E��2\�x�%h�O�_��-�9�'�"`���V_�?���~=� �6@m	���\����'�|��{��5���/����F�^���T�t��Јyu���K�� E>�����P��/>��˅u�m��*�Ě��TR�5��'��V�Ʌ��@�=�,�L=���2cs�j_�wr9�N嬝�Pͧɼ����D��0']�&�l��z^��p���}��W:f��p��nk�C����1�����~�d;E�Lp8;��di�YC}JM��qP����}�����Kf�m(LSEM�u ���ѧ��:�2+�m7aT��Ѵ�2�9^,ǩũ4fb,�����܉\���	�%�j�hB�d��;�#�ʋ�T)(O>
j�X�~!ɸcШ~~�?P5��x�t�f�t ��wn��M7�|�L��Y�?���Uy�Z��=�m����+���2��m��U<�vڨm�Z�A�nʄ�US�p�d�*��!�c�G��Α�<�ܵ>�;\X�ڋ�h0t�N��g2��gޣ���؏�A�u�r�O����5�7\���E�D���0���*k�
F�H�ήcē�L��
�U�tI�;6���2�/�8yBv�}:O����bR\��fh[�� +�m��ҚJO�VF�,��֐��t�.��v�<���Th�]v!��i�S�+����
�G�k�`~�"�m؈�ގ��2�R7g|'.��\@&W����E��ǌ*��q���))��{D��uk3`�MXqhp��b�����x�9u�J�6��*���>�E��Rt��x�}G�Y}C����#÷\2?��X�^�p�5��V�٨��5{�ӨpO;-�;\ q|a��ȥ��k�q�r.�kC�%v����}�.��wA���Yєr�Q�	�Kb����Zm�m�����>��W�p���q�k�MFO�ǈ�?WЏ�����u��w���C�֓w���CaH����egV�1�p�]_R�<:TJ�g��N�މ�T�W�����^o(܆Ӹ�r�-������.kQ�K2���w��.�v��������=�o}�?�>a�J���:�2�j4�+WL��"��+=�dj|�BJ��L	LZ�o6��a.V�{����He;cOtm�g��dMKș#q����DK��;JJӍ+���,���"� �2�,�`�OC}����᷼��~D$zD�,��>�z�i�VZ`�c�mI0v!;Ƚ��ҍݼ��oNFۍ����=���^n�p�N*gK�
�)V'�+�q�E䢲q.���.��5��X�*�a�-#���?k�I�      �   G  x^���N�@�;O17 i��q�d"�D���ײ�M����.QN@��
iB(�+̾�A1�⥇mv��ɯ�N�٪߶��l�@�x��$P�VL$����~�	T��`q���n��R���"t�'�x\W�����ނJ́�%O�'8hى|�x�+�[|�5~���3Z����3fv�S*����Y�Q��$l1�|31��t{Fl�r����4��D��;�	��1�6�ӂ��a���\�86�E{��K�z�+��`N^�U��t�eJ3�a�@v���w#������`g�M��ىM���>
G���~R�2���&�R�gT�      �   �  x^ݙ[o�8���+���	rxW�
�@�.�����Um�jK�%���=�D�V�>�Y��Ι�������~(��}��x8~��kv춇U���Z�u�tųz�(�r�JO�_X�?�ë��m�U�W�~QT����sX�6x�>l�~�Ympǋ��ݢx�~�M��l���uϋO/����}�.�(8�O�[⤗\/�
!Jmq1NBx��O���mSo�n}�߽}����I���/I)R_�RɩԎI�,#�[(^5_�_�����~�3@V9�G̥�!��sd�R���$�U#������j����P����)�������H�`���@�<�Kl�R�RZ&��F�7u�~i�H��uw��M$׈rz ��*�eJk�6�n#y��	u9�/
��東��~��,��":�|������0�𺔎�pH��(ob^��*�1�*X=�V�K�����M�;�^f�'�8�����	��R+F��O�h}����H����/�fZH�̹����`�?�'�s׌ϣ�0.�8��{ `�v `t�F/�}�K�q�j�⟽@�����F`��)=ό Z`G��ʤ��g�+�>
pF{���u�I5�@�R��GC�� �� q����3��˿��t�iK>%D�� �����}�D���p睆*h~�UQst���!��2���9l�!�!��V�k�H(�֋t(ʾD �$�/ȗC�D� �'�"FFH��W�pr�DG��kX�3�^�'���vZ�=%!�"��[��F���ÜD)�t�9$� �<���lh��<�v��^g�(�p8+���ē!�m�#�(9.�$�Cy6E��X
&ԥ�}2VT�̂�Ð�����^ ��{�=6� �T�iC�.������v�!���1Awc/pa�`W%7�s�����!���?}��u���dHd^�Bi�'�a�5yޖ}16�o��77�|�l�      �   g  x^͕[O�0�����`�vӡ1�i.vӹ�Cwq�
�;�:�O���*m���f~rv���O�O�zX�n�`� �\U��]���q�����o|k`��t�څ�v�ZT����:}�DKS�v�]XT��Q��`B��ja��>��||qt�hpv�m����)ٍ�� �8N����q��	"� �B .5� �8eJF����� h��~���|J�,#GZ`�b��ƴ׶z��R��+?KL�;�J3eYbB�T�5)5e!�Fu�� o[ �(!$¬����R��Lj� �%��\��t�yF��[p8���Y�22��o������`�фBŐ�iJ2��(}&���s�;ߚ�_L���C'��Y��l���EjmIU)F��k97���TY��!�0�q�&�"'��׾r����h�m�s�cLg��E�����y���8[��TS1WB%+%1SA"'���d)?�P��M�|���j)�,�=3ԦY,M�������RS9�c�<[S�4�;?*��l�t~	�������"��x��n6N���FDs�����b��8V&�����1[%�H�`i���Gc��F�mI^;&�dyg�	�:��     