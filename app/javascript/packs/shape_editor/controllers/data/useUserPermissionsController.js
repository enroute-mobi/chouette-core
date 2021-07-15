import useSWR from 'swr'

import store from '../../shape.store'

export default function useUserPermissionsController(_isEdit, baseURL) {
  // Event handlers
  const onSuccess = permissions => {
    store.setAttributes({ permissions })
  }
  
  return useSWR(`${baseURL}/shapes/get_user_permissions`, { onSuccess })
}