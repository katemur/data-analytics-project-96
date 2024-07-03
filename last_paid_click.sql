with tab as (
    select
        s.visitor_id,
        max(s.visit_date) as max_date
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    group by s.visitor_id
)

select
    tab.visitor_id,
    tab.max_date as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from tab
left join
    sessions as s
    on tab.visitor_id = s.visitor_id and tab.max_date = s.visit_date
left join leads as l on tab.visitor_id = l.visitor_id
order by 8 desc nulls last, 2, 3, 4, 5
limit 10;
