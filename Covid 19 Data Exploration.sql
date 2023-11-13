Select *
From PortfolioProject..CovidDeaths
order by 3,4

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where Location = 'Portugal'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select Location, date, Population, total_cases, (total_cases/Population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where Location = 'Portugal'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
where continent is not null
Group by Location, Population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by Location
order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

-- Total Cases, Total Deaths and Death % By Date
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Group By date
order by 1,2

-- Total Cases, Total Deaths and Death
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RunningTotalVaccinations, People_Fully_Vaccinated, VaccinatedPeoplePercentage)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(Partition by dea.location Order by dea.location, dea.date) as RunningTotalVaccinations, vac.people_fully_vaccinated, (vac.people_fully_vaccinated/dea.population)*100 AS VaccinatedPeoplePercentage
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select *
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RunningTotalVaccinations numeric,
People_fully_vaccinated numeric,
VaccinatedPeoplePercentage float
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(Partition by dea.location Order by dea.location, dea.date) as RunningTotalVaccinations, CONVERT(int, vac.people_fully_vaccinated), (vac.people_fully_vaccinated/dea.population)*100 AS VaccinatedPeoplePercentage
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
DROP view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(Partition by dea.location Order by dea.location, dea.date) as RunningTotalVaccinations, vac.people_fully_vaccinated, (vac.people_fully_vaccinated/dea.population)*100 AS VaccinatedPeoplePercentage
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

-- Percentage People Vaccinated by location
Select location, MAX(VaccinatedPeoplePercentage) AS VaccinatedPeoplePercentage, MAX(CONVERT(int,people_fully_vaccinated)) AS PeopleVaccinated, MAX(population) AS Population
FROM PercentPopulationVaccinated
WHERE VaccinatedPeoplePercentage < 100
GROUP BY location
ORDER BY Population DESC;

-- Percentage People Vaccinated Worldwide
Select SUM(PeopleVaccinated) AS TotalPeopleVaccinated, SUM(Population) AS TotalPopulation, SUM(PeopleVaccinated) / SUM(Population) AS VaccinatedPeoplePercentage
FROM(
Select MAX(CONVERT(int,people_fully_vaccinated)) AS PeopleVaccinated, MAX(population) AS Population
FROM PercentPopulationVaccinated
WHERE VaccinatedPeoplePercentage < 100
GROUP BY location)
PercentPopulationVaccinated;
