import useSWR from 'swr'

import store from '../../shape.store'

export default function useUserPermissionsController(_isEdit, baseURL) {
  // Event handlers
  const onSuccess = permissions => {
    store.receivePermissions({ permissions })
  }
  
  useSWR(`${baseURL}/shapes/get_user_permissions`, { onSuccess })
}
