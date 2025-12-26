SELECT * 
FROM layoffs;

#making another copy of table to work on
CREATE TABLE layoffs_stg
LIKE layoffs;

SELECT *
FROM layoffs_stg;

#insert values from the previous table
INSERT INTO layoffs_stg
SELECT *
FROM layoffs;

#check for duplicates 
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
) AS rn
FROM layoffs_stg;

WITH dup_cte AS(
	SELECT * ,
	ROW_NUMBER() OVER(
	PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
	) AS rn
	FROM layoffs_stg
)
SELECT *
FROM dup_cte
WHERE rn >1	#these are the records that occur more than once
;

#create another table with 'rn' column included
CREATE TABLE layoffs_stg2
LIKE layoffs_stg;

ALTER TABLE layoffs_stg2
ADD COLUMN rn INT;

SELECT *
FROM layoffs_stg2;

#copy values
INSERT INTO layoffs_stg2
SELECT * ,
	ROW_NUMBER() OVER(
	PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
	) AS rn
FROM layoffs_stg;

#now remove duplicate values
DELETE
FROM layoffs_stg2
WHERE rn>1;

SELECT *
FROM layoffs_stg2
WHERE rn>1;

#duplicate values have been removed

#STANDARDIZING DATA

#removing whitespaces from company column
SELECT company, TRIM(company)
FROM layoffs_stg2;

UPDATE layoffs_stg2
SET company = TRIM(company);

#check for distinct values with same meanings
SELECT DISTINCT industry 
FROM layoffs_stg2
ORDER BY 1;

SELECT * 
FROM layoffs_stg2
WHERE industry LIKE 'crypto%';

UPDATE layoffs_stg2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';


SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) 
FROM layoffs_stg2
ORDER BY 1;

UPDATE layoffs_stg2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'united states%';

#setting date's datatype from text to date
SELECT `date`, STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_stg2;

UPDATE layoffs_stg2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_stg2
MODIFY COLUMN `date` date;


#NULL or BLANK values

SELECT DISTINCT industry
FROM layoffs_stg2
ORDER BY 1;

SELECT * 
FROM layoffs_stg2
WHERE industry IS NULL 
OR industry LIKE '';

#set blank spaces to null
UPDATE layoffs_stg2
SET industry = NULL
WHERE industry LIKE '';

SELECT t1.company,t1.industry,t2.industry
FROM layoffs_stg2 t1
JOIN layoffs_stg2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL
;

#now update the values
UPDATE layoffs_stg2 t1
JOIN layoffs_stg2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL
;

#check for companies with null values in both total_laid_off and percentage_laid_off
SELECT *
FROM layoffs_stg2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

#delete these rows as they are not providing any valueable info
DELETE
FROM layoffs_stg2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
 
 SELECT * 
 FROM layoffs_stg2;
 
 #remove the extra column 'rn' that we created at the start
 ALTER TABLE layoffs_stg2
 DROP COLUMN rn;
 
 #HERE IS THE CLEANED DATA 
 SELECT * 
 FROM layoffs_stg2;