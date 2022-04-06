/*
* This file is a generated Typescript file for GRPC Gateway, DO NOT MODIFY
*/
export interface InitReq extends RequestInit {
  pathPrefix?: string
}
export function fetchReq<I, O>(path: string, init?: InitReq): Promise<O> {
  const {pathPrefix, ...req} = init || {}
  const url = pathPrefix ? ` + "`${pathPrefix}${path}`" + ` : path
  return fetch(url, req).then(r => r.json()) as Promise<O>
}
// NotifyStreamEntityArrival is a callback that will be called on streaming entity arrival
export type NotifyStreamEntityArrival<T> = (resp: T) => void
/**
 * fetchStreamingRequest is able to handle grpc-gateway server side streaming call
 * it takes NotifyStreamEntityArrival that lets users respond to entity arrival during the call
 * all entities will be returned as an array after the call finishes.
 **/
export async function fetchStreamingRequest<S, R>(path: string, callback?: NotifyStreamEntityArrival<R>, init?: InitReq) {
  const {pathPrefix, ...req} = init || {}
  const url = pathPrefix ?` + "`${pathPrefix}${path}`" + ` : path
  const result = await fetch(url, req)
  // needs to use the .ok to check the status of HTTP status code
  // http other than 200 will not throw an error, instead the .ok will become false.
  // see https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#
  if (!result.ok) {
    const resp = await result.json()
    const errMsg = resp.error && resp.error.message ? resp.error.message : ""
    throw new Error(errMsg)
  }
  if (!result.body) {
    throw new Error("response doesnt have a body")
  }
  await result.body
    .pipeThrough(new TextDecoderStream())
    .pipeThrough<R>(getNewLineDelimitedJSONDecodingStream<R>())
    .pipeTo(getNotifyEntityArrivalSink((e: R) => {
      if (callback) {
        callback(e)
      }
    }))
  // wait for the streaming to finish and return the success respond
  return
}
/**
 * JSONStringStreamController represents the transform controller that's able to transform the incoming
 * new line delimited json content stream into entities and able to push the entity to the down stream
 */
interface JSONStringStreamController<T> extends TransformStreamDefaultController {
  buf?: string
  pos?: number
  enqueue: (s: T) => void
}
/**
 * getNewLineDelimitedJSONDecodingStream returns a TransformStream that's able to handle new line delimited json stream content into parsed entities
 */
function getNewLineDelimitedJSONDecodingStream<T>(): TransformStream<string, T> {
  return new TransformStream({
    start(controller: JSONStringStreamController<T>) {
      controller.buf = ''
      controller.pos = 0
    },
    transform(chunk: string, controller: JSONStringStreamController<T>) {
      if (controller.buf === undefined) {
        controller.buf = ''
      }
      if (controller.pos === undefined) {
        controller.pos = 0
      }
      controller.buf += chunk
      while (controller.pos < controller.buf.length) {
        if (controller.buf[controller.pos] == '\n') {
          const line = controller.buf.substring(0, controller.pos)
          const response = JSON.parse(line)
          controller.enqueue(response.result)
          controller.buf = controller.buf.substring(controller.pos + 1)
          controller.pos = 0
        } else {
          ++controller.pos
        }
      }
    }
  })
}
/**
 * getNotifyEntityArrivalSink takes the NotifyStreamEntityArrival callback and return
 * a sink that will call the callback on entity arrival
 * @param notifyCallback
 */
function getNotifyEntityArrivalSink<T>(notifyCallback: NotifyStreamEntityArrival<T>) {
  return new WritableStream<T>({
    write(entity: T) {
      notifyCallback(entity)
    }
  })
}
