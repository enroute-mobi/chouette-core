import useSWR from 'swr'

import store from '../../shape.store'

export default function useUserPermissionsController(baseURL) {
  // Event handlers
  const onSuccess = permissions => {
    store.setAttributes({ permissions })
  }
  
  return useSWR(`${baseURL}/shapes/get_user_permissions`, { onSuccess })
}