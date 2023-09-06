/*
Covid 19 Data Exploration 
*/

Select * from CovidDeaths
where continent is not null 
order by 3, 4 


--Select * from CovidVaccination
--order by 3, 4 ; 

--Select Data that I am going to put in here 

Select location, date, total_cases, new_cases, population, total_deaths
from CovidDeaths
where continent is not null 

order by Location asc; 


-- Total Cases vs Total Deaths ;
-- for all the cases what percentage of people died? 

--Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
--from CovidDeaths
--order by 1,2;

-- total_cases is nvarchar so let's convert it to a float and execute; 

UPDATE CovidDeaths
SET total_cases = CAST(total_cases AS FLOAT);

--Lets execute the percentage now 
-- likelihood of you dying if you get covid in your country; 
Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from covidDeaths
where location like 'india'  
order by 1,5

--lets look at total_cases vs population
--to get a glance at the percentage of population that caught covid-19
Select location, date,population,total_cases, (total_cases/population)*100 AS PopulationInfected
from covidDeaths
where location like 'india' 
order by 1,5

-- i think this is insane even after being a population of 1.4 billion the country managed to control the 
-- population and keep the people safe,
-- as only 3% of the people actually died from covid. 
-- let's compare it to United States of America; 

Select location, date,population,total_cases, (total_cases/population)*100 AS PopulationInfected
from covidDeaths
where location like '%states%'
order by 1,5

-- as of today 30% of people die from covid which is an insanely high number considering the population is not as 
-- big as India.

-- let's have a look at countries with highest infection rate vs the populatiomn 

select location, population , max(total_cases) as HighestInfectionCount,
max((total_cases/population))*100 as PopulationInfected
from CovidDeaths
where continent is not null 
--where location like 'india'
--where location like '%states%'
group by location, population
order by PopulationInfected desc

--in top 10 only south korea is one of the big countries to have been majorly affected by covid-19

-- let's look at the countries with the highest death count per population; 

select location, max(cast(total_deaths as int)) as HighestDeathCount
from coviddeaths

group by location
order by HighestDeathCount desc

-- we have some data in our location column that really shouldn't belong here like high income, upper middle income etc..
-- it is because in some continents the value is null and the continent is written down in location instead of having a country's 
-- name there
-- so i will add where continent is not null to every script and look at how it looks now 

select location, max(cast(total_deaths as int)) as HighestDeathCount
from coviddeaths
where continent is not null
group by location
order by HighestDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT NOW--

-- looking at the continent with the highest death count

	select continent, max(cast(total_deaths as int)) as HighestDeathCount
	from coviddeaths
	where continent is not null
	group by continent
	order by HighestDeathCount desc

--Looking at GLOBAL NUMBERS

select date, sum(new_cases) as totat_cases_new, sum(new_deaths) as total_deaths_new, 
(sum(new_deaths)/ nullif (sum(new_cases), 0))*100 as DeathPercentage
from coviddeaths
where continent is not null 
group by date
order by 4

--let's look at the death percentage across the world

select sum(new_cases) as totat_cases_new, sum(new_deaths) as total_deaths_new, 
(sum(new_deaths)/ nullif (sum(new_cases), 0))*100 as DeathPercentage
from coviddeaths
where continent is not null 

--// so across the world the total cases were 700million and death were approx 7 million, which is less than 1%
-- which i believe is a good thing. Covid-19 is not as deadly as we assumed it to be initially. \

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- let's look at the other table now that we seperated on excel before beginning this project. 

select * from CovidVaccination

--let's join both the tables 

select * from coviddeaths dea
Join CovidVaccination vax

	on dea.location = vax.location and dea.date = vax.date; 


-- the join looks fine, as I compared the columns from both the tables visually. 

-- looking at total_population vs the vaccination 

select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null 
order by 2,3

-- I wanna know what's the rolling count per country as this displays the new vaccinations per day for each location
-- here's how I did it

select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location) as Total_Vaccinations_Taken
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null 
order by 2,3

-- in this table there is a problem, when we scroll down we see that there are some new vaccination number in the 5th column
-- but it is not adding up as the figure in the 6th column stays same through the table for each location, so let's make some 
-- adjustments. 

select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null 
order by 2,3

--//now we can verify that it is adding up all the new vaccination coming up. That's perfect! 

-- now look athe numbers and find out what percentage of people were vaccinated in each country

--USE common table expressions to create temp table to get the results because I can't use the column I just created 
--to give me certain percentages when compared to other columns

with PopVsVac(Continent, location, date, population, new_vaccinations, RollingCountVaccination)
as
(select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null )
select *, (RollingCountVaccination/Population)*100 as RollingPercentage from PopVsVac

-- let's look at the percentage of population who got vaccinated in India till now

with PopVsVac(Continent, location, date, population, new_vaccinations, RollingCountVaccination)
as
(select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null )

select *, (RollingCountVaccination/Population)*100 as RollingPercentage 
from PopVsVac
where location like 'India'; 

-- so we see that the final percentage is 149% which seems a bit odd 
--but that is because people got multiple vaccinations that is why the number is more than 100%


--Just another way of creating TEMP TABLE and get the rolling count percentage\

Create Table #PopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population float,
new_vaccinations float,
RollingCountVaccination float,
)
insert into #PopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null 

select *, (RollingCountVaccination/Population)*100 as RollingPercentage 
from #PopulationVaccinated

--let's look at the percentage of united states of america 

select *, (RollingCountVaccination/Population)*100 as RollingPercentage 
from #PopulationVaccinated
where location like '%states%'

-- number is 200% because of people taking multiple dosages, but that is weird because in news I saw a lot of people 
-- in states were against the vaccination and still the percentage seems good

-- now I want to make some alteration in the querry I want to check for all the values of continent

drop table if exists #PopulationVaccinated
Create Table #PopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population float,
new_vaccinations float,
RollingCountVaccination float,
)
insert into #PopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date


select continent, max(RollingCountVaccination/Population)*100 as RollingPercentage 
from #PopulationVaccinated
where continent is not null
group by continent
	

-- Create our view to store data for later visualizations

Create View PopulationVaccinatedPercentage
as select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
sum(isnull (cast(new_vaccinations as bigint), 0)) OVER (Partition by dea.location order by dea.location,
dea.date) as RollingCountVaccination
from CovidDeaths dea Join CovidVaccination vax
on dea.location = vax.location and dea.date = vax.date
where dea.continent is not null 

-- let's check our view

select * from PopulationVaccinatedPercentage

-- Gorgeous! it worked. 
