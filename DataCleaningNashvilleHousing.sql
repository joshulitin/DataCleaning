-- Cleaning Data in SQL Queries

-- Simple Queries

-- Showing Everything
SELECT *
From NashvilleDataCleaning.dbo.NashvilleHousing
order by [UniqueID ]

--------------------------------------------------------------------------------------
-- Standardize Date Format

Select SaleDateConverted, CONVERT(Date, SaleDate) as Converted
From NashvilleDataCleaning.dbo.NashvilleHousing

-- First Way
Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)
--------------------------------------------------------------------------------------
-- Populate Proper Address data
Select *
From NashvilleDataCleaning.dbo.NashvilleHousing
Where PropertyAddress is null

Select *
From NashvilleDataCleaning.dbo.NashvilleHousing
order by ParcelID

-- IF Parcel ID's are the same, POPULATE the Property Address
Select parcA.ParcelID, parcA.PropertyAddress, parcB.ParcelID, parcB.PropertyAddress, ISNULL(parcA.PropertyAddress, parcB.PropertyAddress) 
From NashvilleDataCleaning.dbo.NashvilleHousing parcA
JOIN NashvilleDataCleaning.dbo.NashvilleHousing parcB
	on parcA.ParcelID = parcB.ParcelID
	AND parcA.[UniqueID ] <> parcB.[UniqueID ]
-- Where parcA.PropertyAddress is null

Update parcA
SET PropertyAddress = ISNULL(parcA.PropertyAddress, parcB.PropertyAddress)
From NashvilleDataCleaning.dbo.NashvilleHousing parcA
JOIN NashvilleDataCleaning.dbo.NashvilleHousing parcB
	on parcA.ParcelID = parcB.ParcelID
	AND parcA.[UniqueID ] <> parcB.[UniqueID ]
Where parcA.PropertyAddress is null
--------------------------------------------------------------------------------------
-- Breaking out Address into Indiviudal Columns (Address, City, State)

--Splitting Address and City
Select PropertyAddress
From NashvilleDataCleaning.dbo.NashvilleHousing

-- Splits Address from City
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From NashvilleDataCleaning.dbo.NashvilleHousing

-- Adds address without City
ALTER TABLE NashvilleHousing
Add PropertySplitAddress NVarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

-- Adds City without address
ALTER TABLE NashvilleHousing
Add PropertySplitCity NVarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Checking for updated table
SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
From NashvilleDataCleaning.dbo.NashvilleHousing
order by PropertyAddress

-- Using ParseName to split Adress, City, and State
-- Parsename orders data backwards so use 3, 2, 1 ... instead of 1, 2, 3 ...
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From NashvilleDataCleaning.dbo.NashvilleHousing

-- Adds Address without City and State
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress NVarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- Adds City without Address and State
ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Adds State without Address and City
ALTER TABLE NashvilleHousing
Add OwnerSplitState NVarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Checking for updated table
SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From NashvilleDataCleaning.dbo.NashvilleHousing
order by OwnerAddress
--------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

-- Checks amount of data using Count
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleDataCleaning.dbo.NashvilleHousing
Group by SoldAsVacant

-- Changes Y to Yes
Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
From NashvilleDataCleaning.dbo.NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
--------------------------------------------------------------------------------------
-- Remove Duplicates

-- Use CTE, Find duplicate values via windows functions

-- Write Query first

-- Adds 'row_num' Column to check for duplicates, if row_num > 1, duplicate exists
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference 
				 ORDER BY UniqueID) row_num
From NashvilleDataCleaning.dbo.NashvilleHousing
Order by ParcelID

-- Use CTE to delete
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference 
				 ORDER BY UniqueID) row_num
From NashvilleDataCleaning.dbo.NashvilleHousing
--Order by ParcelID
)
DELETE
From RowNumCTE
Where row_num > 1
--------------------------------------------------------------------------------------
-- Delete Unused Columns
-- NOTE: Be careful of using this on any RAW data from your source, check with others before doing anything

Select *
From NashvilleDataCleaning.dbo.NashvilleHousing

-- Deletes column
ALTER TABLE NashvilleDataCleaning.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
