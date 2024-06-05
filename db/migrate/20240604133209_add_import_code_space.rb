class AddImportCodeSpace < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :imports do |t|
        t.references :code_space, index: false
      end

      reversible do |direction|
        direction.up   do
          Import::Base.reset_column_information

          update_query = <<~SQL
            UPDATE public.imports SET code_space_id = (
              SELECT public.code_spaces.id
              FROM public.workbenches
              INNER JOIN public.workgroups ON public.workgroups.id = public.workbenches.workgroup_id
              LEFT JOIN public.code_spaces ON public.code_spaces.workgroup_id = public.workgroups.id AND public.code_spaces.short_name = 'external'
              WHERE public.workbenches.id = public.imports.workbench_id
            )
          SQL

          Import::Base.connection.execute update_query

          change_column_null :imports, :code_space_id, false
        end
      end
    end
  end
end
