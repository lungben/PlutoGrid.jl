# PlutoGrid

A viewer for tabular data in Pluto. Input can be any Tables.jl compatible table.

Compared to the standard Pluto table view, this viewer includes sorting and filtering options in the table GUI as well as (optional) pagination.

This viewer is based on [AG-Grid](https://www.ag-grid.com/) [Community Edition](https://github.com/ag-grid/ag-grid).

## Usage

Write in a Pluto cell:

```
## cell
begin
    using Pkg
    Pkg.activate(mktempdir())
    Pkg.add(url="https://github.com/lungben/PlutoGrid.jl")
    using PlutoGrid
end

## cell
df = DataFrame(...)

## cell
readonly_table(df)
```

## API Documentation


	readonly_table(df; sortable=true, filterable=true, pagination=false)

Shows a non-editable table in Pluto.

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

