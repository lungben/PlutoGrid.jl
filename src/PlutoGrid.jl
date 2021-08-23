module PlutoGrid

using HypertextLiteral: @htl
using Tables
using DataFrames

export readonly_table

function make_col_defs(df; filterable=true)
    column_defs = Dict[]
	for c in names(df)
		
		col_dict = Dict("field" => c)
		
		# special types and filters for specific element types
		if eltype(df[!, c]) <: Number
			col_dict["type"] = "numericColumn"
			filterable && (col_dict["filter"] = "agNumberColumnFilter")
		end
		# ToDo: add type / filter for dates

		push!(column_defs, col_dict)
	end
    return column_defs
end

prepare_data(df) = [NamedTuple(row) for row in Tables.rows(df)]

readonly_table(df; kwargs...) = readonly_table(DataFrame(df); kwargs...)


"""
	readonly_table(df; sortable=true, filterable=true, pagination=false)

Shows a non-editable table in Pluto.

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function readonly_table(df:: DataFrame; sortable:: Bool=true, filterable:: Bool=true, pagination:: Bool=false, height:: Integer=600)
	column_defs = make_col_defs(df; filterable)
	data = prepare_data(df)
    return readonly_table(column_defs, data; sortable, filterable, pagination, height)
end

readonly_table(column_defs:: AbstractVector{<: AbstractDict}, data:: AbstractVector; 
	sortable=true, filterable=true, pagination=false, height:: Integer=600) = @htl("""
<html lang="en">
<head>
    <script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.js"></script>
<script>
const columnDefs = $(column_defs);

// specify the data
const rowData = $(data);

// let the grid know which columns and what data to use
const gridOptions = {
  columnDefs: columnDefs,
  rowData: rowData,
  defaultColDef: {
    filter: $(sortable),
    sortable: $(filterable)
  },
  pagination: $(pagination)
};

// setup the grid after the page has finished loading
document.addEventListener('DOMContentLoaded', () => {
    const gridDiv = document.querySelector('#myGrid');
    new agGrid.Grid(gridDiv, gridOptions);
});

</script>
</head>
<body>
    <div id="myGrid" style="height: $(height)px;" class="ag-theme-alpine"></div>
</body>
</html>
""")

# precompilation
let
	df = DataFrame(x=1:10, y=10:-1:1)
	readonly_table(df)
end
	
end
