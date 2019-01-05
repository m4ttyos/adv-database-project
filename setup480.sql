set echo on 
set serveroutput on
spool d:setup480.txt

/* this is the package enroll */
create or replace package enroll as

procedure ValidStud(
	p_snum IN students.snum%type,
	p_answer OUT varchar2);

procedure ValidClasses(
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure RepeatEnroll(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2);

procedure DoubleEnroll(
	p_snum IN enrollments.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure HourRule(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure StandingReq(
	p_snum IN students.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure Disqualified(
	p_snum IN students.snum%type,
	p_answer OUT varchar2);

procedure ClassCap(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure RepeatWait(
	p_snum IN students.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure AddMe(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_ErrorMsg OUT varchar2);

procedure NotEnrolled(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2);

procedure Graded(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2);

procedure DropStu(
	p_snum varchar2,
	p_callnum varchar2);

procedure CheckWait(
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2);

procedure DropMe(
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type);
end enroll;
/
show err
pause

/* this is the body package */
create or replace package body enroll as

procedure ValidStud (
	p_snum IN students.snum%type,
	p_answer OUT varchar2) as
	v_count number;

begin
	select count(*) into v_count
	from students
	where snum=p_snum;

	if v_count=1 then
		p_answer:= null;
	else
		p_answer:= 'The student does not exist.';
	end if;
end;

procedure ValidClasses(
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_count number;

begin
	select count(*) into v_count
	from schclasses
	where callnum=p_CallNum;

	if v_count=1 then
		p_answer:= null;
	else
		p_answer:= 'This call num does not exist.';
	end if;
end;

procedure RepeatEnroll(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2) as
	v_count number;
begin
	select count(*) into v_count
	from enrollments
	where snum=p_snum
	and callnum=p_callnum;

	if v_count=1 then
		p_answer:= 'Student is already enrolled.';
	else
		p_answer:= null;
	end if;
end;

procedure DoubleEnroll(
	p_snum IN enrollments.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_count number;
	v_sect schclasses.section%type;
	v_dept schclasses.dept%type;
	v_cnum schclasses.cnum%type;
begin
	select dept, cnum into v_dept, v_cnum
	from schclasses
	where callnum=p_callnum;

	select section into v_sect
	from schclasses sc, enrollments e
	where sc.callnum=e.callnum
	and e.snum=p_snum
	and sc.dept=v_dept
	and sc.cnum=v_cnum;

	select count(*) into v_count
	from enrollments e, schclasses sc
	where e.callnum=sc.callnum
	and e.snum=p_snum
	and dept=v_dept
	and cnum=v_cnum
	and section=v_sect;
	
	if v_count=1 then 
		p_answer:= 'Student is already taking this course.';
	else
		p_answer:= null;
	end if;
exception
	when others then
	null;
end;

procedure HourRule(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_s_crhr number;
	v_c_crhr number;

begin
	select nvl(sum(c.crhr),0) into v_s_crhr
	from students s, enrollments e, schclasses sc, courses c
	where e.snum=p_snum 
	and s.snum=e.snum
	and e.callnum=sc.callnum
	and sc.dept=c.dept and sc.cnum=c.cnum;

	select c.crhr into v_c_crhr
	from schclasses sc, courses c
	where sc.callnum=p_CallNum
	and sc.dept=c.dept and sc.cnum=c.cnum;
	
	if v_s_crhr + v_c_crhr<=15 then 
		p_answer:= null;
	else
		p_answer:= 'Over credit hours limit.';
	end if;
end;

procedure StandingReq(
	p_snum IN students.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_stu_s students.standing%type;
	v_c_s courses.standing%type;
begin
	select standing into v_stu_s
	from students
	where snum=p_snum;
	
	select standing into v_c_s
	from schclasses sc, courses c
	where sc.dept=c.dept 
	and sc.cnum=c.cnum
	and sc.callnum=p_callnum;
	
	if v_stu_s >= v_c_s then
		p_answer:= null;
	else
		p_answer:= 'Student does not have high enough standing.';
	end if;
end;

procedure Disqualified(
	p_snum IN students.snum%type,
	p_answer OUT varchar2) as
	v_stand students.snum%type;
	v_gpa students.gpa%type;
begin
	select standing, gpa into v_stand, v_gpa
	from students
	where snum=p_snum;
	
	if v_stand!=1 and v_gpa<2 then 
		p_answer:= 'Student is in disqualified status.';
	else
		p_answer:= null;
	end if;
end;

procedure ClassCap(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_count number;
	v_c_count number;
	v_cap number;
begin
	select count(*) into v_count
	from students
	where snum=p_snum;

	select count(*) into v_c_count
	from enrollments
	where callnum=p_callnum
	and grade is null;

	select capacity into v_cap
	from schclasses
	where callnum=p_CallNum;
	
	if v_count + v_c_count <= v_cap then
		p_answer:= null;
	else
		p_answer:= 'Not enough space.';
	end if;
end;

procedure RepeatWait(
	p_snum IN students.snum%type,
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	v_count number;
	v_sname students.sname%type;
begin
	select count(*) into v_count
	from wait
	where snum=p_snum
	and callnum=p_callnum;
	
	if v_count=1 then
		p_answer:= 'Student is already in the waitlist for this class.';
	else
		insert into wait values (p_snum, p_callnum, systimestamp);
		p_answer:= 'Student number ' ||p_snum||' is now on the waiting list for class number '||p_callnum||'.';
	end if;
end;

procedure AddMe(
	p_snum IN students.snum%type,
	p_CallNum IN schclasses.callnum%type,
	p_ErrorMsg OUT varchar2) as
	p_answer varchar2(2000);
begin
	ValidStud (p_snum, p_answer);
	p_ErrorMsg:= p_answer;
	ValidClasses (p_callnum, p_answer);
	p_ErrorMsg:= p_ErrorMsg|| p_answer;

	if p_ErrorMsg is not null then 
		dbms_output.put_line (p_ErrorMsg);
	else
		RepeatEnroll (p_snum, p_callnum, p_answer);
		p_ErrorMsg:= p_ErrorMsg || p_answer;
		DoubleEnroll (p_snum, p_callnum, p_answer);
		p_ErrorMsg:= p_ErrorMsg || p_answer;

		if p_ErrorMsg is not null then
			dbms_output.put_line (p_ErrorMsg);
		else
			HourRule (p_snum, p_Callnum, p_answer);
			p_ErrorMsg:= p_ErrorMsg || p_answer;
			StandingReq (p_snum, p_callnum, p_answer);
			p_ErrorMsg:= p_ErrorMsg || p_answer;

			if p_ErrorMsg is not null then
				dbms_output.put_line (p_ErrorMsg);
			else
				Disqualified (p_snum, p_answer);
				p_ErrorMsg:= p_ErrorMsg || p_answer;

				if p_ErrorMsg is not null then
					dbms_output.put_line (p_ErrorMsg);
				else
					ClassCap (p_snum, p_CallNum, p_answer);
					p_ErrorMsg:= p_ErrorMsg || p_answer;

					if p_ErrorMsg is not null then
						RepeatWait (p_snum, p_callnum, p_answer);
						p_ErrorMsg:= p_ErrorMsg || p_answer;
						dbms_output.put_line (p_ErrorMsg);
					else
						insert into enrollments values (p_snum, p_Callnum, null);
						commit;
						dbms_output.put_line ('Student succesfully enrolled in class.');
					end if;
				end if;
			end if;
		end if;
	end if; 		
end;

procedure NotEnrolled(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2) as
	v_count number;
begin
	select count(*) into v_count
	from enrollments
	where snum=p_snum
	and callnum=p_callnum;

	if v_count=1 then
		p_answer:= null;
	else
		p_answer:= 'Student not enrolled.';
	end if;
end;

procedure Graded(
	p_snum IN enrollments.snum%type,
	p_callnum IN enrollments.callnum%type,
	p_answer OUT varchar2) as
	v_grade enrollments.grade%type;
begin
	select grade into v_grade
	from enrollments
	where snum=p_snum
	and callnum=p_callnum;
	
	if v_grade is null then 
		p_answer:= null;
	else
		p_answer:= 'There is already a grade. Cannot drop.';
	end if;
exception
	when others then
	 null;
end;

procedure DropStu(
	p_snum varchar2,
	p_callnum varchar2) as
begin
	update enrollments
	set grade='W'
	where snum=p_snum
	and callnum=p_callnum;
	
	dbms_output.put_line ('Student has withdrawn from the class.');
end;

procedure CheckWait(
	p_callnum IN schclasses.callnum%type,
	p_answer OUT varchar2) as
	p_ErrorMsg varchar2(1000);
	v_count number;
	v_snum students.snum%type;
	v_callnum schclasses.callnum%type;
	
	Cursor c_checkw is 
	select snum, callnum
	from wait
	where callnum=p_callnum
	order by requestedtime;
begin
	open c_checkw;
	loop
		fetch c_checkw into v_snum, v_callnum;
		exit when c_checkw%NOTFOUND;
	
		Enroll.AddMe (v_snum, v_callnum, p_ErrorMsg);
		p_answer:= p_ErrorMsg;

		select count(*) into v_count
		from enrollments
		where callnum=v_callnum
		and snum=v_snum;
		
		if v_count=1 then
			delete from wait
			where snum=v_snum
			and callnum=v_callnum;
			dbms_output.put_line ('Student ' || v_snum || ' is in '|| v_callnum);
		else
			dbms_output.put_line ('Student ' || v_snum || ' is not in '|| v_callnum);
		end if;
	end loop;
	close c_checkw;
end;

procedure DropMe(
	p_snum students.snum%type,
	p_callnum schclasses.callnum%type) as
	v_errmsg varchar2(1000);
	p_answer varchar2(1000);
begin
	ValidStud (p_snum, p_answer);
	v_errmsg:= p_answer;
	ValidClasses (p_callnum, p_answer);
	v_errmsg:= v_errmsg || p_answer;

	if v_errmsg is not null then 
		dbms_output.put_line (v_errmsg);
	else
		NotEnrolled (p_snum, p_callnum, p_answer);
		v_errmsg:= p_answer;
		Graded (p_snum, p_callnum, p_answer);
		v_errmsg:= v_errmsg || p_answer;

		if v_errmsg is not null then 
			dbms_output.put_line (v_errmsg);
		else
			DropStu (p_snum, p_callnum);
			CheckWait (p_callnum, p_answer);
			dbms_output.put_line (p_answer);
		end if;
	end if;
end;
end enroll;
/
show err
pause

declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (101, 10110, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (103, 10110, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (101, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (102, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (103, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (104, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (105, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (106, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (107, 10135, p_ErrorMsg);
end;
/
declare p_ErrorMsg varchar2(1000);
begin
	enroll.AddMe (108, 10135, p_ErrorMsg);
end;
/
exec Enroll.DropMe (108, 10135);
exec Enroll.DropMe (101, 10135);

spool off;