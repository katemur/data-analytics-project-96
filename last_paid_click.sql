select
	s.visitor_id,
	max(s.visit_date) as visit_date,
	s."source" || '/' || s.medium || '/' || s.campaign as "utm_source/utm_medium/utm_campaign",
	l.lead_id,
	max(l.created_at),
	l.amount,
	l.closing_reason,
	l.status_id
from sessions s
left join leads l on s.visitor_id = l.visitor_id
where s.medium  in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
group by s.visitor_id, s."source", s.medium, s.campaign, l.lead_id, l.amount, l.closing_reason, l.status_id
order by l.amount desc nulls last, max(s.visit_date) asc, "utm_source/utm_medium/utm_campaign" asc
limit 10;
