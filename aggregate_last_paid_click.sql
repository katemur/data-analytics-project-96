with last_paid_click as (
    select
        s.visitor_id,
        max(s.visit_date) as max_date
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    group by s.visitor_id
),

leads_tab as (
    select
        date(lpc.max_date) as visit_date,
        count(distinct lpc.visitor_id) as visitors_count,
        s."source" as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        count(l.lead_id) as leads_count,
        count(
            case
                when
                    l.status_id = 142
                    or l.closing_reason = 'Успешно реализовано'
                    then lpc.visitor_id
            end
        ) as purchases_count,
        sum(l.amount) as revenue
    from last_paid_click as lpc
    inner join
        sessions as s
        on lpc.visitor_id = s.visitor_id and lpc.max_date = s.visit_date
    left join
        leads as l
        on lpc.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    group by 1, 3, 4, 5
),

ads_tab as (
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by 1, 2, 3, 4
    union all
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by 1, 2, 3, 4
)

select
    lt.visit_date,
    lt.visitors_count,
    lower(lt.utm_source) as utm_source,
    lower(lt.utm_medium) as utm_medium,
    lower(lt.utm_campaign) as utm_campaign,
    ads.total_cost,
    lt.leads_count,
    lt.purchases_count,
    lt.revenue
from leads_tab as lt
left join ads_tab as ads
    on
        lt.visit_date = ads.visit_date
        and lower(lt.utm_source) = ads.utm_source
        and lower(lt.utm_medium) = ads.utm_medium
        and lower(lt.utm_campaign) = ads.utm_campaign
order by 9 desc nulls last, 1, 2 desc, 3, 4
limit 15;
