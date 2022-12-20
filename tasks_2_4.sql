-- a.     Попробуйте вывести не просто самую высокую зарплату во всей команде, а вывести именно фамилию сотрудника с самой высокой зарплатой.


select
	e.salary
	,concat(e.last_name, ' ', e.first_name, ' ', e.middle_name)
from employees e
order by e.salary desc
limit 1


-- b.     Попробуйте вывести фамилии сотрудников в алфавитном порядке

select
	e.last_name
from employees e
order by e.last_name asc


-- c.     Рассчитайте средний стаж для каждого уровня сотрудников

select
	l.name
	,work_days
from
(
	select
		e.level_id
		,avg(age(CURRENT_DATE, e.date_from)) as work_days
	from employees e
	group by
		e.level_id
) t
left join levels l
	on l.id = t.level_id


-- d.     Выведите фамилию сотрудника и название отдела, в котором он работает

select
	concat(e.last_name, ' ', e.first_name, ' ', e.middle_name)
	,d.name
from employees e
left join departments d
	on d.id = e.department_id

-- e.     Выведите название отдела и фамилию сотрудника с самой высокой зарплатой в данном отделе и саму зарплату также.

select
	e.last_name
	,d.name
	,t.salary
from
(
	select
		e.id as employee_id
		,e.department_id
		,e.salary
		,max(e.salary) over (partition by e.department_id) as max_dep_salary
	from employees e
) t
left join employees e
	on e.id = t.employee_id
left join departments d
	on d.id = t.department_id
where
	t.salary = t.max_dep_salary	


-- f.      *Выведите название отдела, сотрудники которого получат наибольшую премию по итогам года. Как рассчитать премию можно узнать в последнем задании предыдущей домашней работы

select
	d.name
	,dep_bonus
from
(
	select
		t.department_id
		,sum(t.bonus) as dep_bonus
	from
	(
		select
			e.department_id
			,(t.grade_shift * e.salary) as bonus
		from
		(
			select
				e.id as employee_id
				,sum(g.grade_shift) as grade_shift
			from employees e
			left join employee_grades eg
				on eg.employee_id = e.id
					and eg.year = 2022
			left join grades g
				on g.id = eg.grade_id
			group by
				e.id
		) t
		left join employees e
			on e.id = t.employee_id
		left join positions p
			on p.id = e.position_id
	) t
	group by
		t.department_id
) t
left join departments d
	on d.id = t.department_id
order by dep_bonus desc
limit 1

-- g.    *Проиндексируйте зарплаты сотрудников с учетом коэффициента премии. Для сотрудников с коэффициентом премии больше 1.2 – размер индексации составит 20%, для сотрудников с коэффициентом премии от 1 до 1.2 размер индексации составит 10%. Для всех остальных сотрудников индексация не предусмотрена.

	update employees as e
		set salary = e.salary * b.mult_coeff
	from 
	(
		select
			t.department_id
			,t.employee_id
			,t.mult_coeff
		from
		(
			select
				t.employee_id
				,concat(e.last_name, ' ', e.first_name, ' ', e.middle_name) as empl_name
				,p.name
				,e.department_id
				,t.grade_shift
				,case
					when t.grade_shift > 0.2 then 1.2
					when t.grade_shift between 1 and 1.2 then 0.1
					else 1
					end as mult_coeff
			from
			(
				select
					e.id as employee_id
					,sum(g.grade_shift) as grade_shift
				from employees e
				left join employee_grades eg
					on eg.employee_id = e.id
						and eg.year = 2022
				left join grades g
					on g.id = eg.grade_id
				group by
					e.id
			) t
			left join employees e
				on e.id = t.employee_id
			left join positions p
				on p.id = e.position_id
		) t
	) b
	where b.employee_id = e.id

/*
h.    ***По итогам индексации отдел финансов хочет получить следующий отчет: вам необходимо на уровень каждого отдела вывести следующую информацию:

                                                    i.     Название отдела
                                                  ii.     Фамилию руководителя
                                                iii.     Количество сотрудников
                                                iv.     Средний стаж
                                                  v.     Средний уровень зарплаты
                                                vi.     Количество сотрудников уровня junior
                                              vii.     Количество сотрудников уровня middle
                                            viii.     Количество сотрудников уровня senior
                                                ix.     Количество сотрудников уровня lead
                                                  x.     Общий размер оплаты труда всех сотрудников до индексации
                                                xi.     Общий размер оплаты труда всех сотрудников после индексации
                                              xii.     Общее количество оценок А
                                            xiii.     Общее количество оценок B
                                            xiv.     Общее количество оценок C
                                              xv.     Общее количество оценок D
                                            xvi.     Общее количество оценок Е
                                          xvii.     Средний показатель коэффициента премии
                                        xviii.     Общий размер премии.
                                            xix.     Общую сумму зарплат(+ премии) до индексации
                                              xx.     Общую сумму зарплат(+ премии) после индексации(премии не индексируются)
                                            xxi.     Разницу в % между предыдущими двумя суммами(первая/вторая)
*/

select
	e.department_id
	,d.head_employee_id
	,count(e.id) over (partition by e.department_id) as staff_qty
	,avg(age(CURRENT_DATE, e.date_from)) over (partition by e.department_id) as avg_exp
	,avg(e.salary) over (partition by e.department_id) as avg_salary
	,sum(case when e.level_id = 1 then 1 else 0 end) over (partition by e.department_id) as jun_qty
	,sum(case when e.level_id = 2 then 1 else 0 end) over (partition by e.department_id) as mid_qty
	,sum(case when e.level_id = 3 then 1 else 0 end) over (partition by e.department_id) as sen_qty
	,sum(case when e.level_id = 4 then 1 else 0 end) over (partition by e.department_id) as head_qty
	-- дальше уже лень писать, но суть понятна
from employees e
left join departments d
	on d.id = e.department_id


