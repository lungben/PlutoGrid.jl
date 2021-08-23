module PlutoGrid

using HypertextLiteral: @htl
using Tables
using DataFrames

export readonly_table, editable_table

function make_col_defs(df; filterable=true, editable_cols=String[])
	setdiff(editable_cols, names(df)) == [] || error("not all columns defined as editable are in input data")
    
	column_defs = Dict[]
	for c in names(df)
		
		col_dict = Dict{String, Any}("field" => c)
		col_dict["editable"] = c ∈ editable_cols
		
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

"""
	readonly_table(df; sortable=true, filterable=true, pagination=false)

Shows a non-editable table in Pluto.

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function readonly_table(df:: DataFrame; filterable:: Bool=true, kwargs...)
	column_defs = make_col_defs(df; filterable)
	data = prepare_data(df)
    return _create_table(column_defs, data; filterable, kwargs...)
end

readonly_table(df; kwargs...) = readonly_table(DataFrame(df); kwargs...)

function editable_table(df:: DataFrame, editable_cols:: AbstractVector{<: AbstractString}=collect(names(df)); filterable:: Bool=true, kwargs...)
	column_defs = make_col_defs(df; filterable, editable_cols)
	data = prepare_data(df)
	return _create_table(column_defs, data; filterable, kwargs...)
end

editable_table(df, editable_cols; kwargs...) = editable_table(DataFrame(df), editable_cols; kwargs...)
editable_table(df; kwargs...) = editable_table(DataFrame(df); kwargs...)

_create_table(column_defs:: AbstractVector{<: AbstractDict}, data:: AbstractVector; 
	sortable=true, filterable=true, resizable=true, pagination=false, height:: Integer=600) = @htl("""
<div id="myGrid" style="height: $(height)px;" class="ag-theme-alpine">
<script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.js"></script>
<script>
var div = currentScript.parentElement;
// set default output value
div.value = null;

const columnDefs = $(column_defs);
const rowData = $(data);

// let the grid know which columns and what data to use
const gridOptions = {
  columnDefs: columnDefs,
  rowData: rowData,
  defaultColDef: {
    filter: $(sortable),
    sortable: $(filterable),
	resizable: $(resizable)
  },
  pagination: $(pagination),
  onCellEditingStopped: function (event) {
	div.value = rowData;
	div.dispatchEvent(new CustomEvent("input"));
  }
};
new agGrid.Grid(div, gridOptions);
</script>
</div>
""")

# precompilation
let
	df = DataFrame(x=1:10, y=10:-1:1)
	readonly_table(df)
	editable_table(df)
end
	
end
