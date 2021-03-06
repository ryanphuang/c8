c8 = new Object()

main = ->
    c8.cons = new CmdLine($("canvas#console"))
    bindInput()
    redraw()
    return

bindInput = ->
    $(document).keypress( (ev) ->
        if ev.which in [13, 32]
            ev.preventDefault()
        if ev.which >= 32 && ev.which <= 126 # printable characters
            c8.cons.insertChar(String.fromCharCode(ev.which))
        return
    )
    $(document).keydown( (ev) ->
        # console.log(ev.which)

        if ev.which in [8, 46, 13, 37, 39, 9]
            ev.preventDefault()
        
        if ev.which == 8 # backspace
            c8.cons.backChar()
        if ev.which == 46 # delete
            c8.cons.delChar()
        if ev.which == 13 # enter
            c8.cons.enter()
        if ev.which == 37 # left
            c8.cons.moveCurLeft()
        if ev.which == 39 # right
            c8.cons.moveCurRight()
        if ev.which == 9 # tab
            c8.cons.insertTab()
    )
    return

lastWinh = -1
fitCanvas = ->
    c = $("canvas#console")
    winh = $(window).height()
    if winh != lastWinh
        h = winh - 40
        if h < 0
            h = 1
        c.height(h)
        lastWinh = winh
    return

redraw = (timestamp) ->
    fitCanvas()
    c8.cons.redraw()
    window.requestAnimationFrame(redraw)
    return

ms = -> (new Date()).getMilliseconds()
monos = 'Consolas, Inconsolata, Monaco, "Courier New", Courier, monospace'
makeFont = (size) -> '' + size + 'px ' + monos

# Grants you the physical layer
Terminal = (canvas) ->
    self = this

    dpr = window.devicePixelRatio
    # dpr = 1
    context = canvas.getContext('2d')
    # context.scale(dpr, dpr)

    fontSize = 14 * dpr
    charHeight = fontSize
    lineMargin = 3 * dpr
    lineHeight = charHeight + lineMargin
    context.font = makeFont(fontSize)
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
        context.font = makeFont(fontSize)
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

    self.clear = ->
        context.clearRect(0, 0, width*dpr, height*dpr)
        return

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

    self.drawCursor = (row, col) ->
        if !self.inRange(row, col)
            return
        p = self.charPos(row, col)
        context.fillRect(p.x, p.y + charHeight,
            charWidth, dpr)
        return
    
    self.clearCursor = (row, col) ->
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
    self.curPos = 0
    self.curRow = 0
    self.curCol = 0
    self.curShow = false
    self.lastMoved = (new Date()).getTime()

    self.drawCursor = ->
        now = (new Date()).getTime()
        delta = now - self.lastMoved
        if delta < 0
            delta = 0

        mod = delta % 1000
        if mod < 500
            if !self.curShow || self.updated
                self.term.drawCursor(self.curRow, self.curCol)
                self.curShow = true
        else
            if self.curShow || self.updated
                self.term.clearCursor(self.curRow, self.curCol)
                self.curShow = false
        return

    self.redraw = ->
        c = self.canvas
        resized = self.term.updateSize(c.width(), c.height())
        if resized || self.updated
            self._redraw(resized)
        else
            self.drawCursor()

        return

    # breaks a line into array of char arrays
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
        if n % ncol == 0
            ret.unshift([])
        return ret

    # calculate the number of rows required to print this line
    lineNrow = (line) ->
        ncol = self.term.ncol()
        if ncol == 0
            return 0
        return Math.ceil((line.length + 1) / ncol)

    self._redraw = (resized) ->
        nrow = self.term.nrow()
        ncol = self.term.ncol()

        buf = []
        lastLineHeight = 0
        
        if self.lines.length > 0
            lastLine = self.lines[0]
            lastNrow = lineNrow(lastLine)
            if self.lastLineHeight > lastNrow
                n = self.lastLineHeight - lastNrow
                if n >= nrow
                    n = nrow - 1 # at most pad nrow -1 lines
                for i in [1..n]
                    buf.unshift([])
                    lastLineHeight++
        
        nline = self.lines.length
        if nline > 0
            lastLine = self.lines[0]
            parts = breakLine(lastLine)
            for p in parts
                buf.unshift(p)
                lastLineHeight++
            
            for line in self.lines.slice(1, nline)
                if buf.length >= nrow
                    break
                parts = breakLine(line)
                for p in parts
                    buf.unshift(p)
                    if buf.length >= nrow
                        break
        
        # just to make sure
        while buf.length > nrow && buf.length > lastLineHeight
            buf.shift() # we can discard this because we have not hit last line yet

        term = self.term
        term.clear()

        row = 0
        for b in buf
            col = 0
            for c in b
                term.drawChar(row, col, c)
                col++
            row++

        curRow = Math.floor(self.curPos / ncol)
        self.curCol = self.curPos - curRow * ncol
        self.curRow = buf.length - lastLineHeight + curRow
        
        self.drawCursor()

        self.updated = false
        return
            
    self.expandLastLineHeight = (line) ->
        nrow = lineNrow(line)
        if self.lastLineHeight < nrow
            self.lastLineHeight = nrow

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
        self.curPos = line.length
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

    self.setCursor = (pos) ->
        if self.curPos != pos
            self.curPos = pos
            self.updated = true
        return

    self.curMoved = ->
        self.lastMoved = (new Date()).getTime()
        return
    
    return

CmdLine = (canvas) ->
    self = this
    self.cons = new Console(canvas)
    self.prompt = c8go.pwd() + '$ '
    self.cons.addLine(self.prompt)
    self.line = ''
    self.curPos = 0
    self.launchFunc = c8go.launch
    self.out = {
        println: (s) ->
            self.cons.addLine(s)
            return
    }
    self.updated = true

    self.redraw = ->
        if self.updated
            self.cons.setLastLine(self.prompt + self.line)
            self.cons.setCursor(self.prompt.length + self.curPos)
            self.updated = false
        self.cons.redraw()
        return
    
    self.insertChar = (c) ->
        line = self.line
        before = line.substr(0, self.curPos)
        after = line.substr(self.curPos, line.length)
        self.line = before + c + after
        self.curPos++
        self.cons.curMoved()
        self.updated = true
        return

    self.insertTab = ->
        # TODO
        self.insertChar(' ')
        self.updated = true
        return

    self.backChar = (c) ->
        if self.curPos > 0
            line = self.line
            before = line.substr(0, self.curPos-1)
            after = line.substr(self.curPos, line.length)
            self.line = before + after
            self.curPos--
            self.cons.curMoved()
        self.updated = true
        return
    
    self.delChar = (c) ->
        line = self.line
        n = line.length
        if self.curPos != n
            before = line.substr(0, self.curPos)
            after = line.substr(self.curPos+1, line.length)
            self.line = before + after
        self.updated = true
        return

    self.moveCurLeft = ->
        if self.curPos > 0
            self.curPos--
            self.cons.curMoved()
        self.updated = true
        return
    
    self.moveCurRight = ->
        if self.curPos < self.line.length
            self.curPos++
            self.cons.curMoved()
        self.updated = true
        return
    
    self.enter = ->
        if self.line.length > 0
            self.launch(self.line)
        self.cons.addLine(self.prompt)
        self.curPos = 0
        self.line = ''
        self.cons.curMoved()
        self.updated = true
        return

    self.launch = (line) ->
        if self.launchFunc == null
            self.cons.addLine('launch func missing')
        else
            self.launchFunc(line, self.out)
        self.prompt = c8go.pwd() + '$ '
        self.updated = true
        return

    return

$(document).ready(main)
