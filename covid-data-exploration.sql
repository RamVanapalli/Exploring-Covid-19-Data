/*
Understanding COVID-19 Patterns Using SQL

What This Project Demonstrates:
- Combining datasets using SQL Joins
- Simplifying queries with Common Table Expressions (CTEs)
- Organizing data with Temporary Tables
- Using Window Functions for running totals
- Aggregating information to draw meaningful conclusions
- Creating reusable SQL Views for visualization
- Handling and transforming data types
*/

-- Query 1: Where do we begin? 🤔
-- Let’s start by looking at rows where the continent is specified. This gives us a clearer picture to work with.
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY continent, location;

-- Query 2: A quick overview 🌍
-- What’s in our dataset? Let’s grab some essential columns to understand cases, deaths, and populations at a glance.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- Query 3: How deadly is COVID-19? 💀
-- What would be the death rate for people who contract COVID-19? Let’s calculate using the total cases and deaths.
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
ORDER BY location, date;

-- Query 4: Infection vs Population 🧑‍🤝‍🧑
-- Hmm, let’s figure out how much of the population was infected. What percentage does it add up to? 🤔
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;

-- Query 5: Which countries suffered the most? 📊
-- Let’s dig deeper to see which countries had the highest infection rates compared to their population.
SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Query 6: Where were the most deaths? ⚰️
-- Let’s explore the places with the highest death tolls. This could reveal areas hit hardest.
SELECT 
    location, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Query 7: Deaths by continent 🌎
-- How do continents compare? Let’s check where the highest death tolls occurred globally.
SELECT 
    continent, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Query 8: What’s happening globally? 🌐
-- Let’s sum up the cases and deaths worldwide. Also, what’s the overall death rate? Let’s calculate.
SELECT 
    SUM(new_cases) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY TotalCases, TotalDeaths;

-- Query 9: Tracking vaccinations 💉
-- Hmm, how are vaccinations progressing over time? Let’s calculate the rolling totals per location.
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date;

-- Query 10: Vaccination insights using CTE 🧠
-- Let us now calculate vaccination rates in a reusable way by breaking it down into steps.
WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopVsVac;

-- Query 11: Save it for later! 📝
-- Let’s store the rolling vaccination data into a temporary table so we can explore it further.
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    NewVaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date;

SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Query 12: Vaccination view setup 👀
-- Let’s make a view so we can easily pull vaccination data for dashboards or further analysis.
CREATE OR ALTER VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
