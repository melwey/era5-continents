# era5-continents
Rasterize a vector layer of the world continents to match the ERA5 grid.

Either with this [python Notebook](https://github.com/melwey/era5-continents/tree/master/pyCode/rasterize_continents.ipynb), saving the result as a NETCDF file.

Or with this [Julia script](https://github.com/melwey/era5-continents/tree/master//juliaCode/rasterize_continents.jl), saving the result as a Zarr data cube. This approach still requires python to download some data from the Copernicus Data Store.