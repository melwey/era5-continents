using YAXArrays, EarthDataLab
import NetCDF, ArchGDAL
import Dates
using UnicodePlots

# download World_Continents from ESRI
if !isdir("../data/") 
    mkdir("../data/")
end
if !isfile("../data/World_Continents.zip")
        download("https://opendata.arcgis.com/api/v3/datasets/57c1ade4fa7c4e2384e6a23f2b3bd254_0/downloads/data?format=shp&spatialRefId=4326&where=1%3D1",
            "../data/World_Continents.zip")
end


if !isdir("../output/") 
    mkdir("../output/")
end

if isfile("../output/World_Continents_raster_0d25_180jl.tif")
    rm("../output/World_Continents_raster_0d25_180jl.tif")
end

# load modules if on cluster
if haskey(ENV,"LOADEDMODULES")
    run(`ml gnu12/12.2.0  openmpi4/4.1.4 gdal/3.5.3`)
end
# run(`gdal_rasterize -l World_Continents -at -a FID -tr 0.25 0.25 -te -180.125 -90.125 179.875 90.125 -a_srs EPSG:4326 -a_nodata 0.0 -ot Byte /vsizip/../data/World_Continents.zip/World_Continents.shp ../output/World_Continents_raster_0d25_180jl.nc`)
run(`gdal_rasterize -l World_Continents -at -a FID -tr 0.25 0.25 -te -180.125 -90.125 179.875 90.125 -a_srs WGS84 -a_nodata 0.0 -ot Byte /vsizip/../data/World_Continents.zip/World_Continents.shp ../output/World_Continents_raster_0d25_180jl.tif`)

# dsn = YAXArrays.open_dataset("../output/World_Continents_raster_0d25_180jl.nc", driver = :netcdf)
dst = open_dataset("../output/World_Continents_raster_0d25_180jl.tif", driver = :gdal)

# cn = YAXArrays.Cube(dsn) # ERROR: ArgumentError: Could not promote element types of cubes in dataset to a common concrete type, because of Variable crs
ct = Cube(dst)
dt = copy(ct.data)
heatmap(replace(dt'[end:-1:1,:], missing => 0))
# shift data
tmp = range(-180,179.75,1440)
circshift(tmp, 180*4)

dts = circshift(dt, (180*4, 0))
heatmap(replace(dts'[end:-1:1,:], missing => 0))
# # convert missing to 0
# replace!(dt, missing => 0)
# 

# About ERA5 grid: https://confluence.ecmwf.int/display/CKB/ERA5%3A+What+is+the+spatial+reference
# ERA5 grid at 0.25 resoltion has 1440 by 721 cells with 
# longitude values in the range [0; 360] referenced to the Greenwich Prime Meridian and 
# latitude values in the range [-90; +90] referenced to the equator. 
# The ERA5 data points coordinates reference the centre of the tiles. There are no points or tiles at Lon=360.

# GeoTiff references the top left of the tile. Hence, the axes have to be shifted to match the ERA5 datasets.

# use the land sea mask as model.
if !isfile("../data/land_sea_mask.nc")
    run(`python ../pyCode/download_lsm.py`)
end

lsm = open_dataset("../data/land_sea_mask.nc")
lsm_notime = lsm.lsm[time = 1]
axs = lsm_notime.axes

props = Dict(
    "name" => "cont",
    "continents" => Dict(
        1 => "Africa", 
        2 => "Asia", 
        3 => "Australia", 
        4 => "North America",
        5 => "Oceania", 
        6 => "South America", 
        7 => "Antarctica",  
        8 => "Europe",
        ),
    "projection" => "EPSG:4326",
    "source" => "ESRI https://opendata.arcgis.com/api/v3/datasets/57c1ade4fa7c4e2384e6a23f2b3bd254_0",
    "processing" => "gdal_rasterize -l World_Continents -at -a FID -tr 0.25 0.25 -te -180.125 -90.125 179.875 90.125 -a_srs EPSG:4326 -a_nodata 0.0 -ot Byte src dst",
    "Date" => Dates.today(),
)

continents = Dataset(cont = YAXArray(axs, dts, props))
# use same chunking as ERA5cube
continents_chunked = setchunks(continents, Dict("longitude" => 60, "latitude" => 60))
savedataset(continents_chunked, path = "../output/continents.zarr", backend = :zarr, overwrite=true, )
