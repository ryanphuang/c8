c8 = new Object()

main = ->
    cons = new Console($("canvas#console"))
    # cons.addLine("")
    # cons.addLine("Hello, world!")
    # cons.addLine("")

    c8.console = cons

    redraw()
    return

redraw = (timestamp) ->
    winh = $(window).height()
    c = $("canvas#console")
    c.height(winh - 40)
    
    cons = c8.console
    cons.setLastLine('The time now is: ' + new Date())
    cons.redraw()

    window.requestAnimationFrame(redraw)
    return

# Grants you the physical layer
Terminal = (canvas) ->
    self = this

    dpr = window.devicePixelRatio
    context = canvas.getContext('2d')
    context.scale(dpr, dpr)

    fontSize = 14 * dpr
    charHeight = fontSize
    lineMargin = 3 * dpr
    lineHeight = charHeight + lineMargin
    context.font = '' + fontSize + 'px Consolas'
    charWidth = context.measureText('M').width # calculate char width

    width = 0
    height = 0
    nrow = 0
    ncol = 0

    self.sayHello = ->
        s = "j$ Hello world!"
        i = 0
        for c in s.split('')
            self.drawChar(0, i, c)
            self.drawChar(1, i, c)
            i++
        return
    
    self.updateSize = (w, h) ->
        if (w == width && h == height)
            return false

        canvas.width = w * dpr
        canvas.height = h * dpr
        context.font = '' + fontSize + 'px Consolas'
        context.fillStyle = '#ddd'
        context.textBaseline = 'bottom'

        width = w
        height = h
        nrow = Math.floor(height * dpr / lineHeight)
        ncol = Math.floor(width * dpr / charWidth)
        return true
    
    self.inRange = (row, col) ->
        if row < 0
            return false
        if row >= nrow
            return false
        if col < 0
            return false
        if col >= ncol
            return false
        return true

    self.charPos = (row, col) ->
        x = col * charWidth
        y = row * lineHeight + dpr
        return { x:x, y:y }

    self.clearChar = (row, col) ->
        if !self.inRange(row, col)
            return
        p = self.charPos(row, col)
        context.clearRect(p.x, p.y, charWidth, charHeight)
        return

    self.clearLine = (row) ->
        for i in [0..ncol-1]
            self.clearChar(row, i)
        return
    
    self.drawChar = (row, col, c) ->
        if !self.inRange(row, col)
            return
        p = self.charPos(row, col)
        context.clearRect(p.x, p.y, charWidth, charHeight)
        context.fillStyle = '#ddd'
        context.fillText(c, p.x, p.y + charHeight)
        return

    self.drawCursor = (row, col, c) ->
        if !self.inRange(row, col)
            return
        p = self.charPos(row, col)
        context.fillRect(p.x, p.y + charHeight,
            charWidth, dpr)
        return
    
    self.clearCursor = (row, col, c) ->
        if !self.inRange(row, col)
            return
        p = self.charPos(row, col)
        context.clearRect(p.x, p.y + charHeight,
            charWidth, dpr)
        return

    self.nrow = -> nrow
    self.ncol = -> ncol

    return

Console = (canvas) ->
    self = this
    self.term = new Terminal(canvas[0])
    self.canvas = canvas # a jquery object
    self.maxLines = 100000
    self.lines = []
    self.updated = true
    self.lastLineHeight = 0

    self.redraw = ->
        c = self.canvas
        resized = self.term.updateSize(c.width(), c.height())
        if resized || self.updated
            self._redraw()
        return

    breakLine = (line) ->
        chars = line.split('')
        n = chars.length
        if n == 0
            ret = []
            ret.unshift([])
            return ret

        ncol = self.term.ncol()
        i = 0
        ret = []
        while i < n
            ret.unshift(chars.slice(i, i+ncol))
            i += ncol
        return ret

    lineNrow = (line) ->
        if line.length == 0
            return 1
        ncol = self.term.ncol()
        if ncol == 0
            return 0
        return Math.ceil(line.length / ncol)

    self._redraw = ->
        buf = []
        
        nline = self.lines.length
        if nline > 0
            lastLine = self.lines[0]
            lastNrow = lineNrow(lastLine)
            if self.lastLineHeight > lastNrow
                n = self.lastLineHeight - lastNrow
                for i in [1..n]
                    buf.unshift([])
        
        nrow = self.term.nrow()
        for line in self.lines
            parts = breakLine(line)
            for p in parts
                buf.unshift(p)
            if buf.length >= nrow
                break
        while buf.length > nrow
            buf.shift()

        term = self.term
        row = 0
        for b in buf
            col = 0
            term.clearLine(row)
            for c in b
                term.drawChar(row, col, c)
                col++
            row++

        self.updated = false
        return
            
    self.expandLastLineHeight = (line) ->
        nrow = lineNrow(line)
        if self.lastLineHeight < nrow
            self.lastLineHeight = nrow
        self.updated = true

    self.addLine = (line) ->
        if self.lines.length > 0
            lastLine = self.lines[0]
            lastLineHeight = lineNrow(lastLine)
            if self.lastLineHeight > lastLineHeight
                self.lastLineHeight -= lastLineHeight
            else
                self.lastLineHeight = 0

        self.lines.unshift(line)
        if self.lines.length > self.maxLines
            self.lines.pop()
        
        self.expandLastLineHeight(line)
        self.updated = true
        return

    self.getLastLine = ->
        nline = self.lines.length
        if nline == 0
            return ''
        return self.lines[0]

    self.setLastLine = (s) ->
        nline = self.lines.length
        if nline == 0
            self.addLine(s)
        else
            self.lines[0] = s
            self.expandLastLineHeight(s)

        self.updated = true
        return
    
    return

ms = ->
    d = new Date()
    return d.getMilliseconds()


$(document).ready(main)
