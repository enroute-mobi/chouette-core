import '../../helpers/polyfills'
import RefreshForm from '../../exports/RefreshForm'
import MasterSlave from "../../helpers/master_slave"

new MasterSlave("form")

import '../../publication_setups/new'

new RefreshForm('#publication_setup_export_type', '#exported_lines', 'publication_setup').init()
