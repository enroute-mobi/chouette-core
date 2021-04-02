import '../../helpers/polyfills'
import RefreshForm from '../../exports/RefreshForm'

$("#export_referential_id").select2()

new RefreshForm('#export_type', '#exported_lines', 'export').init()
