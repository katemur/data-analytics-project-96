with tab as (
    select
        s.visitor_id,
        max(s.visit_date) as max_date
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    group by s.visitor_id
)

select
    tab.max_date as visit_date,
    s."source" as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    count(tab.visitor_id) as visitors_count,
    case
        when sum(va.daily_spent) is null then sum(ya.daily_spent)
        when sum(ya.daily_spent) is null then sum(va.daily_spent)
        else sum(va.daily_spent) + sum(ya.daily_spent)
    end as total_cost,
    count(l.closing_reason) as purchases_count,
    count(l.lead_id) as leads_count,
    sum(l.amount) as revenue
from tab
inner join
    sessions as s
    on tab.visitor_id = s.visitor_id and tab.max_date = s.visit_date
left join
    leads as l
    on tab.visitor_id = l.visitor_id and s.visit_date <= l.created_at
left join
    vk_ads as va
    on
        s."source" = va.utm_source
        and s.medium = va.utm_medium
        and s.campaign = va.utm_campaign
        and s."content" = va.utm_content
left join
    ya_ads as ya
    on
        s."source" = ya.utm_source
        and s.medium = ya.utm_medium
        and s.campaign = ya.utm_campaign
        and s."content" = ya.utm_content
where l.closing_reason = 'Успешно реализовано' or l.status_id = 142
group by 1, 2, 3, 4
order by 9 desc nulls last, 1 asc, 4 desc, 2 asc, 3 asc, 4 asc
limit 15;