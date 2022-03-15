-- Standardizing Date Format to Get Rid of Timestamp


BEGIN TRANSACTION 
ALTER TABLE dbo.HousingData
ALTER COLUMN SaleDate date
COMMIT TRANSACTION

-- Populate Property Address Data

BEGIN TRANSACTION
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.HousingData a
JOIN dbo.HousingData b ON a.ParcelID = b.ParcelID 
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
COMMIT TRANSACTION

-- Breaking out PropertyAddress into Individual Columns

BEGIN TRANSACTION
ALTER TABLE dbo.HousingData
ADD PropertySplitAddress NVARCHAR(255)
COMMIT TRANSACTION

BEGIN TRANSACTION
UPDATE dbo.HousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)
COMMIT TRANSACTION

BEGIN TRANSACTION
ALTER TABLE dbo.HousingData
ADD PropertySplitCity NVARCHAR(255)
COMMIT TRANSACTION

BEGIN TRANSACTION
UPDATE dbo.HousingData
SET PropertySplitCity = TRIM(SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)))
COMMIT TRANSACTION

-- Breaking out Owner Address

BEGIN TRANSACTION
ALTER TABLE dbo.HousingData
ADD OwnerSplitState NVARCHAR(255),
OwnerSplitCity NVARCHAR(255),
OwnerSplitAddress NVARCHAR(255)
COMMIT TRANSACTION

BEGIN TRANSACTION
UPDATE dbo.HousingData
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)
COMMIT TRANSACTION

-- Change Y and N to Yes and No in Sold As Vacant field (Currently not standardized)

BEGIN TRANSACTION
UPDATE dbo.HousingData
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No' 
WHEN SoldAsVacant = 'Y' THEN 'Yes'
ELSE SoldAsVacant
END
COMMIT TRANSACTION;

-- Remove Duplicates

BEGIN TRANSACTION
WITH row_num AS(
SELECT *, 
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM dbo.HousingData
)
DELETE
FROM row_num
WHERE row_num > 1
COMMIT TRANSACTION

-- Delete Unused Columns

BEGIN TRANSACTION
ALTER TABLE dbo.HousingData
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
COMMIT TRANSACTION