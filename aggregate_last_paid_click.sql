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
        s."source" as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        date(lpc.max_date) as visit_date,
        count(distinct lpc.visitor_id) as visitors_count,
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
    group by date(lpc.max_date), s."source", s.medium, s.campaign
),

ads_tab as (
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by date(campaign_date), utm_source, utm_medium, utm_campaign
    union all
    select
        date(campaign_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by date(campaign_date), utm_source, utm_medium, utm_campaign
)

select
    lt.visit_date,
    lt.visitors_count,
    ads.total_cost,
    lt.leads_count,
    lt.purchases_count,
    lt.revenue,
    lower(lt.utm_source) as utm_source,
    lower(lt.utm_medium) as utm_medium,
    lower(lt.utm_campaign) as utm_campaign
from leads_tab as lt
left join ads_tab as ads
    on
        lt.visit_date = ads.visit_date
        and lower(lt.utm_source) = ads.utm_source
        and lower(lt.utm_medium) = ads.utm_medium
        and lower(lt.utm_campaign) = ads.utm_campaign
order by
    lt.revenue desc nulls last,
    lt.visit_date asc,
    lt.visitors_count desc,
    lower(lt.utm_source),
    lower(lt.utm_medium)
limit 15;
