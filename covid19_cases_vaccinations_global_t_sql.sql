--covid_cases_deaths_percentage_by_country
with sort_by_countries as (
    select 
        *,
        row_number() over (partition by country order by date desc) as latest_updated
    from PorfolioProject..compact$
)
select 
    country, 
    continent, 
    total_cases, 
    total_deaths, 
    population,
    round(cast(total_cases as float) / nullif(population,0) * 100, 2) as cases_percent_over_population,
    round(cast(total_deaths as float) / nullif(population,0) * 100, 2) as deaths_percent_over_population
from sort_by_countries
where latest_updated = 1 and continent is not null and population is not null 
order by country

--total_deaths_and_cases
with sort_by_countries as (
    select
        country,
        continent,
        date,
        total_cases,
        total_deaths,
        row_number() over (partition by country order by date desc) as lastest
    from PorfolioProject..compact$
    where total_cases is not null
),
latest_per_country as (
    select *
    from sort_by_countries
    where lastest = 1 and continent is not null and country is not null
), sort_by_continent as (
    select
        continent,
        sum(cast(total_cases as bigint)) as total_cases_country,
        sum(cast(total_deaths as bigint)) as total_deaths_country
    from latest_per_country
    group by continent
), total_cases_and_deaths as (
    select 
        sum(total_cases_country) as TotalCases,
        sum(total_deaths_country) as TotalDeaths
    from sort_by_continent
)
select 
    * 
from total_cases_and_deaths;


--covid_cases_deaths_percentage_by_continent
with sort_by_countries as (
    select
        country,
        continent,
        date,
        total_cases,
        total_deaths,
        row_number() over (partition by country order by date desc) as lastest
    from PorfolioProject..compact$
    where total_cases is not null
),
latest_per_country as (
    select *
    from sort_by_countries
    where lastest = 1 and continent is not null and country is not null
), 
sort_by_continent as (
    select
        continent,
        sum(cast(total_cases as bigint)) as total_cases_continent,
        sum(cast(total_deaths as bigint)) as total_deaths_continent
    from latest_per_country
    group by continent
)
select 
    continent,
    total_cases_continent,
    round(cast(total_cases_continent as float) / nullif(sum(cast(total_cases_continent as float)) over (), 0) * 100, 2) as percentage_on_overall_cases,
    total_deaths_continent,
    round(cast(total_deaths_continent as float) / nullif(sum(cast(total_deaths_continent as float)) over (), 0) * 100, 2) as percentage_on_overall_deaths
from sort_by_continent
order by continent

--covid_vaccination_percentages_by_country
with lastest_vacination_data as (
    select
        *,
        row_number() over (partition by country order by date desc) as lastest
    from porfolioproject..vaccinations_global$
    where people_fully_vaccinated is not null
), lastest_deaths_cases_data as (
    select
        *,
        row_number() over (partition by country order by date desc) as lastest
    from porfolioproject..compact$
    where total_cases is not null
), lastest_vacination_only as (
    select *
    from lastest_vacination_data
    where lastest = 1
), lastest_deaths_cases_only as (
    select *
    from lastest_deaths_cases_data
    where lastest = 1
)
select
    dc.country,
    dc.continent,
    dc.total_cases,
    dc.total_deaths,
    dc.population,
    vac.total_vaccinations,
    vac.people_fully_vaccinated,
    round(cast(vac.people_fully_vaccinated as float) / nullif(cast(dc.total_cases as float), 0) * 100, 2) as percentage_fully_vaccinated_over_cases,
    round(cast(vac.people_fully_vaccinated as float) / nullif(cast(dc.total_deaths as float), 0) * 100, 2) as percentage_fully_vaccinated_over_deaths,
    round(cast(vac.people_fully_vaccinated as float) / nullif(cast(dc.population as float), 0) * 100, 2) as  percentage_fully_vaccinated_over_population,
    round(cast(vac.people_fully_vaccinated as float) / nullif(cast(vac.total_vaccinations as float), 0) * 100, 2) as  percentage_fully_vaccinated_over_total_vaccinations
from lastest_deaths_cases_only dc
left join lastest_vacination_only vac 
    on vac.country = dc.country
where dc.continent is not null


--covid_vaccination_percentages_by_continent
with lastest_vacination_data as (
    select
        *,
        row_number() over (partition by country order by date desc) as lastest
    from porfolioproject..vaccinations_global$
    where people_fully_vaccinated is not null
), lastest_deaths_cases_data as (
    select
        *,
        row_number() over (partition by country order by date desc) as lastest
    from porfolioproject..compact$
    where total_cases is not null
), lastest_vacination_only as (
    select *
    from lastest_vacination_data
    where lastest = 1
), lastest_deaths_cases_only as (
    select *
    from lastest_deaths_cases_data
    where lastest = 1
), vac_with_continent as (
    select
        vac.country,
        dc.continent,
        vac.people_fully_vaccinated,
        vac.total_vaccinations
    from lastest_vacination_only vac
    left join lastest_deaths_cases_only dc
        on dc.country = vac.country
), continent_totals as (
    select
        dc.continent,
        sum(cast(dc.total_cases as float)) as total_cases_continent,
        sum(cast(dc.total_deaths as float)) as total_deaths_continent,
        sum(cast(dc.population as float)) as population_continent,
        sum(cast(vac.people_fully_vaccinated as float)) as fully_vaccinated_continent,
        sum(cast(vac.total_vaccinations as float)) as total_vaccinations_continent
    from lastest_deaths_cases_only dc
    left join vac_with_continent vac
        on vac.country = dc.country
    group by dc.continent
)
select
    continent,
    total_cases_continent,
    total_deaths_continent,
    population_continent,
    fully_vaccinated_continent,
    total_vaccinations_continent,
    round(fully_vaccinated_continent / nullif(total_cases_continent,0) * 100,2) as percentage_fully_vaccinated_over_cases,
    round(fully_vaccinated_continent / nullif(population_continent,0) * 100,2) as percentage_fully_vaccinated_over_population,
    round(fully_vaccinated_continent / nullif(total_vaccinations_continent,0) * 100,2) as percentage_fully_vaccinated_over_total_vaccinations
from continent_totals
where continent is not null
order by continent
