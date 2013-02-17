class SingleLinkedNode
  constructor: (data)->
    @data = data
    @next = null
  next: ()->



class DoubleLinkedNode
  constructor: (data)->
    @data = data
    @next = @prev = null


class LinkedList
  constructor: (maxSize = -1)->
    @head = @tail = null
    @maxSize  = maxSize
    _circular = false
    _size     = 0
    _nodes    = {}

  empty: ()->
    if _size is 0

