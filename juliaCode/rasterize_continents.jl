import YAXArrays, NetCDF
import ArchGDAL

# if isfile("../output/World_Continents_raster_0d25_180jl.nc")
#     rm("../output/World_Continents_raster_0d25_180jl.nc")
# end

if isfile("../output/World_Continents_raster_0d25_180jl.tif")
    rm("../output/World_Continents_raster_0d25_180jl.tif")
end

# run(`gdal_rasterize -l World_Continents -at -a FID -tr 0.25 0.25 -te -180.125 -90.125 180.125 90.125 -a_srs EPSG:4326 -a_nodata 0.0 -ot Byte /vsizip/../data/World_Continents.zip/World_Continents.shp ../output/World_Continents_raster_0d25_180jl.nc`)
run(`gdal_rasterize -l World_Continents -at -a FID -tr 0.25 0.25 -te -180.125 -90.125 180.125 90.125 -a_srs EPSG:4326 -a_nodata 0.0 -ot Byte /vsizip/../data/World_Continents.zip/World_Continents.shp ../output/World_Continents_raster_0d25_180jl.tif`)

# dsn = YAXArrays.open_dataset("../output/World_Continents_raster_0d25_180jl.nc", driver = :netcdf)
dst = YAXArrays.open_dataset("../output/World_Continents_raster_0d25_180jl.tif", driver = :gdal)

# cn = YAXArrays.Cube(dsn)
ct = YAXArrays.Cube(dst)
d = copy(ct.data)
# convert missing to 0
replace!(d, missing => 0)
sum(d[1,:] .!= d[1441,:])

