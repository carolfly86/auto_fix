unwanted:
select c.*, a.postal_code from customer c join address a on c.address_id = a.address_id where c.customer_id in(select f.customer_id from f_result f full join t_result t on f.customer_id = t.customer_id where t.customer_id is null);
missing
select c.*, a.postal_code from customer c join address a on c.address_id = a.address_id where c.customer_id in(select t.customer_id from f_result f full join t_result t on f.customer_id = t.customer_id where f.customer_id is null);