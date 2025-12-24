import 'axios'

declare module 'axios' {
  export interface AxiosResponse<T = any> {
    code: number
    msg: string
    data: T
  }
}

