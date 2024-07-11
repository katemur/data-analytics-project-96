--расчет из каких платных источников приходит больше пользователей
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
),

lpc_tab as (
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
)

select
    utm_source,
    sum(visitors_count) / (select sum(visitors_count) from lpc_tab
    ) * 100.0 as visitors_percent
from lpc_tab
group by utm_source;

--расчет из каких в общем источников приходят посетители
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
    ads.total_cost,
    lt.visitors_count,
    lt.leads_count,
    lt.purchases_count,
    lt.revenue,
    lower(lt.utm_source) as utm_source,
    lower(lt.utm_medium) as utm_medium,
    lower(lt.utm_campaign) as utm_campaign,
    case
        when lt.visitors_count = 0 or ads.total_cost is null then 0
        else ads.total_cost / lt.visitors_count
    end as cpu,
    case
        when lt.leads_count = 0 or ads.total_cost is null then 0
        else ads.total_cost / lt.leads_count
    end as cpl,
    case
        when lt.purchases_count = 0 or ads.total_cost is null then 0
        else ads.total_cost / lt.purchases_count
    end as cppu,
    case
        when ads.total_cost = 0 or ads.total_cost is null then 0
        else (lt.revenue - ads.total_cost) / ads.total_cost * 100
    end as roi
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
    lower(lt.utm_medium);



-- расчет cpu, cpl, cppu и roi в общем для рекламных кампаний в vk и yandex
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
    lower(lt.utm_source) as utm_source,
    sum(ads.total_cost) as total_cost,
    sum(lt.revenue) as revenue,
    sum(ads.total_cost) / sum(lt.visitors_count) as cpu,
    sum(ads.total_cost) / sum(lt.leads_count) as cpl,
    sum(ads.total_cost) / sum(lt.purchases_count) as cppu,
    (sum(lt.revenue) - sum(ads.total_cost)) / sum(ads.total_cost) * 100 as roi
from leads_tab as lt
left join ads_tab as ads
    on
        lt.visit_date = ads.visit_date
        and lower(lt.utm_source) = ads.utm_source
        and lower(lt.utm_medium) = ads.utm_medium
        and lower(lt.utm_campaign) = ads.utm_campaign
where lt.utm_source = 'yandex' or lt.utm_source = 'vk'
group by lt.utm_source;

-- расчет cpu, cpl, cppu и roi для всех рекламных кампаний
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
    sum(ads.total_cost) / sum(lt.visitors_count) as cpu,
    sum(ads.total_cost) / sum(lt.leads_count) as cpl,
    sum(ads.total_cost) / sum(lt.purchases_count) as cppu,
    (sum(lt.revenue) - sum(ads.total_cost)) / sum(ads.total_cost) * 100 as roi
from leads_tab as lt
left join ads_tab as ads
    on
        lt.visit_date = ads.visit_date
        and lower(lt.utm_source) = ads.utm_source
        and lower(lt.utm_medium) = ads.utm_medium
        and lower(lt.utm_campaign) = ads.utm_campaign

-- расчет корреляции между запуском рекламы и ростом органики

with org as (
    select
        date(visit_date) as visit_date,
        count(distinct visitor_id) as organic
    from sessions
    where "source" = 'organic'
    group by date(visit_date)
),

adv as (
    select
        date(visit_date) as visit_date,
        count(distinct visitor_id) as ads
    from sessions
    where "source" in ('yandex', 'vk')
    group by date(visit_date)
)

select corr(organic, ads) as correlation
from
    (select
        org.visit_date,
        org.organic,
        adv.ads
    from org
    inner join adv on org.visit_date = adv.visit_date) as org_and_adv
