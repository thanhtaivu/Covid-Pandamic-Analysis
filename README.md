# COVID-19 Data Analysis with SQL

## Overview
This project focus on analyzing global COVID-19 data (cases, death, cacination and population impact) using both T-SQL and BigQuery queries
The dataset comes from two table compact$ and vaccinations_global$ in the database which includes information about all section about COVID-19

The goal is to:
- Extract the lastest avaiable data per country
- Aggregate result by continent
- Compare cases, deaths, and vacctionation progress rerlative to population
- Create percentages and ratios to better understand the global distribution

## Tables/Views Created nad Explaintions

## 1. COVID-19 Total Cases and Deaths as a Percentage of Population by Country
- Query
```mysql
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
```
- This table/view shows the latest COVID-19 data for each country, including total cases, total deaths, and continent information. By selecting only the most recent records, it illustrate the current country of the pandemic worldwide. Countries with high totals indicate regions heavily affected, while lower numbers reflect less impact. This analysis provides a clear overview of global trends.

## 2. Global Total COVID-19 Cases and Deaths
- Query
```mysql
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
```
- This query provides a global summary of the total COVID-19 cases and deaths. It begins by identifying the most recent data for each country to ensure that outdated information does not change the analysis. By filtering for the latest record per country, the query captures a snapshot of the pandemic as it current situarion worldwide.

## 3. COVID-19 Cases and Deaths by Continent with Global Percentage
- Query
```mysql
with sort_by_countries as (
    select
        country,
        continent,
        date,
        total_cases,
        total_deaths,
        row_number() over (partition by country order by date desc) as lastest
    from `PorfolioProject.compact$`
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
        sum(cast(total_cases as float64)) as total_cases_continent,
        sum(cast(total_deaths as float64)) as total_deaths_continent
    from latest_per_country
    group by continent
)
select 
    continent,
    total_cases_continent,
    round(total_cases_continent / nullif(sum(total_cases_continent) over (), 0) * 100, 2) as percentage_on_overall_cases,
    total_deaths_continent,
    round(total_deaths_continent / nullif(sum(total_deaths_continent) over (), 0) * 100, 2) as percentage_on_overall_deaths
from sort_by_continent
order by continent;
```
- This query analyzes COVID-19 cases and deaths at the continental level. It identifies the data for each country to ensure accuracy. Then, it aggregates these figures by continent, calculating total cases and deaths per region. To provide perspective on each continent’s contribution to the global pandemic, the query also computes the percentage of total cases and deaths relative to worldwide totals.

## 4. COVID-19 Vaccination Metrics Relative to Cases, Deaths, and Population by Country
- Query
```mysql
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
```
- This query examines COVID-19 vaccination progress at the country level in relation to cases, deaths, and population. It begins by selecting the most recent vaccination data and the latest COVID-19 case and death records for each country to ensure accuracy. By joining these datasets, the query calculates key vaccination percentages: the proportion of fully vaccinated individuals relative to total cases, total deaths, total population, and total vaccinations administered. This analysis provides insight into how effectively countries are progressing in immunizing their populations and highlights the relationship between vaccination efforts and the overall impact of the pandemic.

## 5. COVID-19 Vaccination Coverage and Metrics by Continent
- Query
```mysql
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
```
- This query analyzes COVID-19 vaccination progress at the continental level. It begins by selecting the latest vaccination and COVID-19 case and death data for each country. Country-level vaccination figures are then associated with their respective continents. Aggregating these data by continent provides total cases, total deaths, total population, fully vaccinated individuals, and total vaccinations per region. The query further calculates the proportion of fully vaccinated individuals relative to cases, population, and total vaccinations, offering insight into overall vaccination coverage across continents.

## Conlusion
This analysis provide the comprehensive overview of the global COVID-19 situation combining cases, deaths, and vaccination data at both countries and continent levels. By selecting the lastest available record which provide by the ETL Documentation, the queries ensure accurate and readable. Aggregating data by continent and calculating percentages relative to population, total cases and total vaccination illustrate a clear perspective on the pandamic's impact and the effectiveness of vaccination campaigns worldwide.