--Covid 19 Data Exploration
Select *
From Practice_Data.dbo.CovidDeaths


SELECT location, date, total_cases, new_cases, total_deaths, population
From Practice_Data.dbo.CovidDeaths
Order BY 1, 2

-- Identify the Total cases vs Total Deaths to create the Death Percentage per country by date
---- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS DeathPercentage
FROM Practice_Data.dbo.CovidDeaths
Order BY 1, 2


--Identify the Death Percentage for data (final date is 4/30/21 for data collection)

SELECT location, max(total_cases) as TotalCases, max(total_deaths) as TotalDeaths,
max(total_deaths/total_cases)*100 AS DeathPercentage
FROM Practice_Data.dbo.CovidDeaths
Where continent is not null
Group by location
Order by 1, 2



--Countries with Highest Death Count

SELECT location, max(cast(total_deaths AS int)) as TotalDeathCount
FROM Practice_Data.dbo.CovidDeaths
Where continent is not null
GROUP BY location
Order BY TotalDeathCount DESC



--Continent by Death Count

SELECT location, max(cast(total_deaths AS int)) as TotalDeathCount
FROM Practice_Data.dbo.CovidDeaths
Where continent is null
GROUP BY location
Order BY TotalDeathCount DESC


---Countries with Highest Infection Rate vs Compared to Population
----Shows what percentage of population infected with Covid

SELECT location, population, max(total_cases) as HighestInfectionCount,
max(total_cases/population)*100 AS PercentPopulationInfected
FROM Practice_Data.dbo.CovidDeaths
GROUP BY location, population
Order BY PercentPopulationInfected DESC


--ICU and Hopitalization Data in the US

---U.S. Percentage of Population in the ICU by Date
Select location, date, population, icu_patients, (cast(icu_patients as int)/population)*100 as PercentagePopulationICU
From Practice_Data.dbo.CovidDeaths
Where location = 'United States'
--Where icu_patients is not null
--Order by 1, 2

--US total hospitalizations vs population
Select location, population, Sum(cast(weekly_hosp_admissions as int)) as TotalHospitalAdmissions, 
(Sum(cast(weekly_hosp_admissions as int))/population)*100 as PercentPopHospitalized
From Practice_Data.dbo.CovidDeaths
Where location = 'United States'
Group by location, population

---U.S. Percentage of Population Hosiptalized by Date
Select location, date, population, hosp_patients, weekly_hosp_admissions, (hosp_patients/population)*100 as PercentagePopulationHospitalized
From Practice_Data.dbo.CovidDeaths
Where location = 'United States'




--Global Data
-- Total Global Cases and Deaths/Global Death Percentage by date

SELECT date, Sum(new_cases) AS TotalGLobalCases, Sum(cast(new_deaths AS int)) AS TotalGlobalDeaths,
Sum(cast(new_deaths AS int))/Sum(new_cases)*100 AS GlobalDeathPercentage
FROM Practice_Data.dbo.CovidDeaths
Where continent is not null
GROUP BY date
Order BY 1, 2


-- Max Total World Cases/Deaths (not by Date - End date of data collection 4/30/2021)

SELECT Sum(new_cases) AS TotalGLobalCases, Sum(cast(new_deaths AS int)) AS TotalGlobalDeaths,
Sum(cast(new_deaths AS int))/Sum(new_cases)*100 AS GlobalDeathPercentage
FROM Practice_Data.dbo.CovidDeaths
Where continent is not null
Order BY 1, 2



-- Join Deaths with Vaccination Tables
--Rolling Count of those Vaccinated by Date and Location
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(Cast(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date)AS
RollingCountVaccinated
FROM Practice_Data.dbo.CovidDeaths dea
JOIN Practice_Data.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null
order by 1, 2

---Specififcally looking at Rolling Count of Vaccinations in the US

Select dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(Cast(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date)AS
RollingCountVaccinated
FROM Practice_Data.dbo.CovidDeaths dea
JOIN Practice_Data.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
Where dea.location = 'United States'


-- Using CTE to perform Calculation on Partition By in previous query

--- % of Population Vaccinated by Date
--View US data


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
as RollingPeopleVaccinated--, (RollingPeopleVaccinated/population)*100
From Practice_Data.dbo.CovidDeaths  dea
Join Practice_Data.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--dea.location = 'United States'
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac




--- Temp Table to create perform Calculation on Partition By in previous query: Percent Population Vaccinated
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
From Practice_Data.dbo.CovidDeaths dea
Join Practice_Data.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
From #PercentPopulationVaccinated



---Views--

	--PercentPopuation Vaccnated

Use Practice_Data
GO
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From  Practice_Data.dbo.CovidDeaths dea
Join Practice_Data.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

--- View DeathPercentage

Use Practice_Data
GO
Create View DeathPercentage as
SELECT location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS DeathPercentage
FROM Practice_Data.dbo.CovidDeaths

---View GlobalDeathPercentage

Use Practice_Data
Go
Create View GlobalDeathPercentage as
SELECT date, Sum(new_cases) AS TotalGLobalCases, Sum(cast(new_deaths AS int)) AS TotalGlobalDeaths,
Sum(cast(new_deaths AS int))/Sum(new_cases)*100 AS GlobalDeathPercentage
FROM Practice_Data.dbo.CovidDeaths
Where continent is not null
GROUP BY date
--Order BY 1, 2


---View InfectionRate

Use Practice_Data
Go
Create View InfectionRate as
SELECT location, population, max(total_cases) as HighestInfectionCount,
max(total_cases/population)*100 AS PercentPopulationInfected
FROM Practice_Data.dbo.CovidDeaths
GROUP BY location, population
--Order BY PercentPopulationInfected DESC