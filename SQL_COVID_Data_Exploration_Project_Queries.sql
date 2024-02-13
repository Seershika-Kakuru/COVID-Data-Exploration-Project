SELECT *
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
ORDER BY 3, 4

SELECT *
FROM SQL_Covid_Data_Exploration_Project..covid_vaccinations$
ORDER BY 3, 4

-- Total Cases Vs Total Deaths
-- Likelihood of dying if one intracts COVID in the United States
SELECT Location, Date, total_cases, total_deaths, ((CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100) AS DeathPercentage
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
WHERE Location COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '%States' AND Continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases Vs Population
-- What percentage of tested population who got covid in the United States
SELECT Location, Date, total_cases, population, ((CONVERT(float, total_cases) / CONVERT(float, population)) * 100) AS PercentageOfPopulationInfected
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
WHERE Location COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '%States' AND Continent IS NOT NULL
ORDER BY 1, 2

-- Showing countries with the Highest Infection Rate when compared to the Population
SELECT Location, Population, MAX(CONVERT(float, total_cases)) HighestInfectionCount, MAX(((CONVERT(float, total_cases) / CONVERT(float, Population)) * 100)) AS PercentOfPopulationInfected
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
 WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentOfPopulationInfected DESC, Location

-- Showing Countries and the Total Death Count Per Country For Each Year
SELECT Location, YEAR(date), SUM(CAST(total_deaths AS INT)) TotalDeathCountPerYear
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
WHERE Continent IS NOT NULL
GROUP BY Location, YEAR(date)
ORDER BY YEAR(date), TotalDeathCountPerYear DESC

-- Building up on previous query: Showing the countries with the Highest Death Count For Each Year
;WITH CTE_TotalDeath_MaxDeath AS (
SELECT Location, Year, TotalDeathCountPerYear, MAX(TotalDeathCountPerYear) OVER (PARTITION BY Year) HighestDeathCountForYear
FROM (
SELECT Location, YEAR(date), SUM(CAST(total_deaths AS INT)) TotalDeathCountPerYear
FROM SQL_Covid_Data_Exploration_Project..covid_deaths$
WHERE Continent IS NOT NULL
GROUP BY Location, YEAR(date)) [TotalDeathCountPerCountryPerYear] (Location, Year, TotalDeathCountPerYear)
)
SELECT Year, Location, HighestDeathCountForYear
FROM  CTE_TotalDeath_MaxDeath
WHERE TotalDeathCountPerYear = HighestDeathCountForYear

-- Finding the maximum total deaths for a day in different locations
SELECT location, MAX(CAST(total_deaths AS INT)) MaxDeathCount
FROM SQL_Covid_Data_Exploration_Project.dbo.covid_deaths$
WHERE continent IS NULL AND location IN ('Asia', 'North America', 'South America', 'Africa', 'Europe', 'Antarctica', 'Oceania')
GROUP BY location
ORDER BY MaxDeathCount DESC

-- Showing new cases and new deaths for each day
SELECT date, SUM(CAST(new_cases AS FLOAT)) TotalNewCases, SUM(CAST(new_deaths AS FLOAT)) TotalNewDeaths
FROM SQL_Covid_Data_Exploration_Project.dbo.covid_deaths$
GROUP BY date
HAVING SUM(CAST(new_cases AS INT)) > 0
ORDER BY date

-- New Vaccinations, Cumulative Sum of New Vaccinations, CurrentVaccinatedPopulationRate
;WITH Rolling_Vaccinations_Info_CTE AS(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
	   SUM(CONVERT(FLOAT, new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) cumulative_vaccinations_total
FROM SQL_Covid_Data_Exploration_Project.dbo.covid_deaths$ AS deaths
JOIN SQL_Covid_Data_Exploration_Project.dbo.covid_vaccinations$ AS vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL AND new_vaccinations IS NOT NULL)
SELECT continent, location, date, population, new_vaccinations, cumulative_vaccinations_total, 
	   cumulative_vaccinations_total/population * 100 'CurrentVaccinatedPopulationRate (%)'
FROM Rolling_Vaccinations_Info_CTE
ORDER BY location, date


-- Creating a temp table with rolling vaccination information for each day for each location
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
continent varchar(255),
location varchar(255),
date datetime, 
population float,
new_vaccinations float,
cumulative_vaccinations_total float )

INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
	   SUM(CONVERT(FLOAT, new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) cumulative_vaccinations_total
FROM SQL_Covid_Data_Exploration_Project.dbo.covid_deaths$ AS deaths
JOIN SQL_Covid_Data_Exploration_Project.dbo.covid_vaccinations$ AS vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL AND new_vaccinations IS NOT NULL

-- Creating a temp table with the latest date for each country
DROP TABLE IF EXISTS #LatestDate
CREATE TABLE #LatestDate (
continent varchar(255),
location varchar(255),
latest_date datetime)

INSERT INTO #LatestDate
SELECT continent, location, MAX(date)
FROM #PercentPopulationVaccinated
GROUP BY continent, location


-- Getting the Current Vaccinated Population Rate information as of the latest available date for each location
SELECT per.continent, per.location, latest.latest_date, per.population, per.new_vaccinations, per.cumulative_vaccinations_total,
	per.cumulative_vaccinations_total/per.population * 100 'CurrentVaccinatedPopulationRate (%)'
FROM #PercentPopulationVaccinated per
JOIN #LatestDate latest
ON per.continent = latest.continent
AND per.location = latest.location
AND per.date = latest.latest_date

-- Creating a view to store information for future visualizations
CREATE VIEW PercentPopulationVaccinatedView AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, 
	   SUM(CONVERT(FLOAT, new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) cumulative_vaccinations_total
FROM SQL_Covid_Data_Exploration_Project.dbo.covid_deaths$ AS deaths
JOIN SQL_Covid_Data_Exploration_Project.dbo.covid_vaccinations$ AS vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL AND new_vaccinations IS NOT NULL

SELECT *
FROM PercentPopulationVaccinatedView













