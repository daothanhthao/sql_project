select *
from NashvilleHousing;
--standardize date format
alter table Nashvillehousing
add saledateconverted Date;
update NashvilleHousing
set saledateconverted= convert(date,saledate);
select saledateconverted
from NashvilleHousing;
 --populate property address data
 select PropertyAddress
 from NashvilleHousing
 where PropertyAddress is null;

select a.ParcelID, a.PropertyAddress,b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
	where a.PropertyAddress is null;

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;

--Breaking out Address into Individual Columns (Address, City, State)
select propertyaddress
from nashvillehousing;
select substring(propertyaddress,1,charindex(',',propertyaddress)-1) as address
from nashvillehousing;
select substring(propertyaddress,charindex(',',propertyaddress)+1,len(propertyaddress)) as city
from nashvillehousing;

alter table nashvillehousing
add propertysplitaddress nvarchar(255),
	propertycity nvarchar(255); 

update nashvillehousing
set propertysplitaddress = substring(propertyaddress,1,charindex(',',propertyaddress)-1),
	propertycity = substring(propertyaddress,charindex(',',propertyaddress)+1,len(propertyaddress));

select owneraddress
from nashvillehousing;
select 
parsename(replace(owneraddress,',','.'),3),
parsename(replace(owneraddress,',','.'),2),
parsename(replace(owneraddress,',','.'),1)
from nashvillehousing 

alter table nashvillehousing
add OwnerSplitAddress nvarchar(255),
	OwnerSplitcity nvarchar(255),
	OwnerSplitstate nvarchar(255);

update nashvillehousing
set OwnerSplitAddress = parsename(replace(owneraddress,',','.'),3),
	OwnerSplitcity = parsename(replace(owneraddress,',','.'),2),
	OwnerSplitstate = parsename(replace(owneraddress,',','.'),1);

-- Change Y and N to Yes and No in "Sold as Vacant" field
select distinct(SoldAsVacant),count(SoldAsVacant)
from nashvillehousing
group by SoldAsVacant
order by 2;

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
from nashvillehousing; 

update nashvillehousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
					end;
-- Remove Duplicates
with rownumcte as(
select *,
	ROW_NUMBER() over(
	partition by parcelid, propertyaddress, saledate, saleprice, legalreference
	order by uniqueid) row_num
from nashvillehousing)

select * 
from rownumcte
where row_num>1
--order by PropertyAddress

---- Delete Unused Columns
select *
from NashvilleHousing;

alter table NashvilleHousing
drop column propertyaddress, saledate, owneraddress, taxdistrict;
