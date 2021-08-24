module PlutoGrid

using HypertextLiteral: @htl, JavaScript
using Tables
using DataFrames

export readonly_table, editable_table, create_dataframe

function make_col_defs(df; filterable=true, editable_cols=String[])
	setdiff(editable_cols, names(df)) == [] || error("not all columns defined as editable are in input data")
    
	column_defs = Dict[]
	for c in names(df)
		col_dict = Dict{String, Any}("field" => c)

		col_is_editable = c ∈ editable_cols
		col_dict["editable"] = col_is_editable
		
		# special types and filters for specific element types
		if eltype(df[!, c]) <: Number
			col_dict["type"] = "numericColumn"
			filterable && (col_dict["filter"] = "agNumberColumnFilter")
			col_is_editable && (col_dict["valueParser"] = JavaScript("numberParser"))
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

`resizable`: allows resizing of column widths in GUI (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function readonly_table(df:: DataFrame; filterable:: Bool=true, kwargs...)
	column_defs = make_col_defs(df; filterable)
	data = prepare_data(df)
    return _create_table(column_defs, data; filterable, kwargs...)
end

readonly_table(df; kwargs...) = readonly_table(DataFrame(df); kwargs...)

"""
	@bind edits editable_table(df, [editable_cols]; sortable=true, filterable=true, pagination=false, height=600, return_only_modified=false)

Shows an editable table in Pluto. In case of user edits in the table, 

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`editable_cols`: (optional) Names of columns which are editable. If not given, all columns are editable.

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`resizable`: allows resizing of column widths in GUI (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function editable_table(df:: DataFrame, editable_cols:: AbstractVector{<: AbstractString}=collect(names(df)); filterable:: Bool=true, return_only_modified:: Bool=false, kwargs...)
	column_defs = make_col_defs(df; filterable, editable_cols)
	data = prepare_data(df)
	return _create_table(column_defs, data; editable=true, filterable, kwargs...)
end

editable_table(df, editable_cols; kwargs...) = editable_table(DataFrame(df), editable_cols; kwargs...)
editable_table(df; kwargs...) = editable_table(DataFrame(df); kwargs...)

edit_buttons = @htl("""
	<button  
		id="update_grid"
		type="button">
			Confirm  
	</button>
""")

edit_button_callbacks = JavaScript("""
div.querySelector("button#update_grid").addEventListener("click", (e) => {
	div.value = rowData; // return complete table
	div.dispatchEvent(new CustomEvent("input"));
	e.preventDefault();
	});
""")

function _create_table(column_defs:: AbstractVector{<: AbstractDict}, data:: AbstractVector; 
	sortable=true, filterable=true, resizable=true, pagination=false, height:: Integer=600,
	editable=false)

	return @htl("""
<div id="myGrid" style="height: $(height)px;" class="ag-theme-alpine">
$(editable ? edit_buttons : "")
<script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.js"></script>
<script>

function numberParser(params) {
	return Number(params.newValue);
};

var div = currentScript.parentElement;
// set default output value
div.value = null;

$(editable ? edit_button_callbacks : JavaScript(""))

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
  undoRedoCellEditing: true,
  onCellValueChanged: function (params) {
	// source: https://angularquestions.com/2019/08/21/ag-grid-how-to-update-a-specific-cell-style-after-click/
	const focusedCell =  params.api.getFocusedCell();
	const rowNode = params.api.getRowNode(focusedCell.rowIndex);
	const column = focusedCell.column.colDef.field;
	focusedCell.column.colDef.cellStyle = { 'background-color': 'yellow' };
	params.api.refreshCells({
		force: true,
		columns: [column],
		rowNodes: [rowNode]
	});
	}
};
new agGrid.Grid(div, gridOptions);

</script>
</div>
""")
end

"""
	create_dataframe(x)

Utility function to create a DataFrame from a `@bind` variable of a `editable_table`.
"""
create_dataframe(::Nothing) = DataFrame()
create_dataframe(::Missing) = DataFrame()
create_dataframe(x:: Dict) = DataFrame(x)

function create_dataframe(x:: AbstractVector)
	df = DataFrame()
	for row in x
		push!(df, row; cols=:union)
	end
	return df
end

# precompilation
let
	df = DataFrame(x=1:10, y=10:-1:1)
	readonly_table(df)
	editable_table(df)
end
	
end
