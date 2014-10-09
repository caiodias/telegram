//
//  TGCTextView.m
//  Telegram
//
//  Created by keepcoder on 01.10.14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "TGCTextView.h"


@interface DrawsRect : NSObject

@property(nonatomic,assign) CGColorRef color;
@property (nonatomic,assign) CGRect rect;

@end


@implementation DrawsRect


@end
@interface TGCTextView () {
    NSArray *drawRects;
}
@property (nonatomic, strong) NSTrackingArea *trackingArea;

@property (nonatomic,strong) NSArray *links;
@property (nonatomic,assign) BOOL needUpdateTrackingArea;
@property (nonatomic,assign) NSSize currentSize;
@property (nonatomic,strong) TGCTextMark *realMark;
@property (nonatomic,strong) NSMutableArray *marks;


@end

@implementation TGCTextView



-(id)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        self.wantsLayer = YES;
        self.selectColor = NSColorFromRGBWithAlpha(0x1d80cc, 0.5);
        self.backgroundColor = [NSColor whiteColor];
        _marks = [[NSMutableArray alloc] init];
    }
    
    return self;
}


-(void)updateTrackingAreas
{
    if(_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways);
    _trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}


//-(void)updateTrackingAreas {
//    
//    if(!self.needUpdateTrackingArea)
//        return;
//    
//    
//    if(self.trackingArea) {
//        [self removeTrackingArea:self.trackingArea];
//    }
//    
//    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
//                                                     options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect)
//                                                       owner:self userInfo:nil];
//    
//    [self addTrackingArea:self.trackingArea];
//    
//    self.needUpdateTrackingArea = NO;
//}
//
//-(void)setFrameSize:(NSSize)newSize {
//    
//    if(newSize.width != self.currentSize.width || newSize.height != self.currentSize.height) {
//        self.currentSize = newSize;
//        self.needUpdateTrackingArea = YES;
//        [super setFrameSize:newSize];
//    }
//    
//    [self setNeedsDisplay:YES];
//   
//}

-(void)setAttributedString:(NSAttributedString *)attributedString {
    self->_attributedString = attributedString;
    
    [self.marks removeAllObjects];
    self.realMark = nil;
    
    startSelectPosition = NSMakePoint(-1, -1);
    currentSelectPosition = NSMakePoint(-1, -1);
    
   [self setSelectionRange:NSMakeRange(NSNotFound,0)];
}

-(void)setNeedsDisplay:(BOOL)flag {
    
    [super setNeedsDisplay:flag];
}

-(void)setEditable:(BOOL)isEditable {
    self->_isEditable = isEditable;
    
    [self setNeedsDisplay:YES];
}

-(void)setSelectionRange:(NSRange)selectionRange {
    
    
    startSelectPosition = NSMakePoint(-1, -1);
    currentSelectPosition = NSMakePoint(-1, -1);
    
    if(self.realMark && self.selectRange.location == selectionRange.location && self.selectRange.length == selectionRange.length)
        return;
    
    
    [self.marks removeObject:self.realMark];
    
    self.realMark = [[TGCTextMark alloc] initWithRange:selectionRange color:self.selectColor isReal:YES];

    [self.marks addObject:self.realMark];
    
    [self setNeedsDisplay:YES];
}

-(void)addMark:(TGCTextMark *)mark {
    if(mark) {
        [self.marks addObject:mark];
        [self setNeedsDisplay:YES];
    }
}

-(void)addMarks:(NSArray *)marks {
    if(marks.count > 0) {
        [self.marks addObjectsFromArray:marks];
        [self setNeedsDisplay:YES];
    }
}

-(void)setBackgroundColor:(NSColor *)backgroundColor {
    self->_backgroundColor = backgroundColor;
    
  //  self.layer.backgroundColor = backgroundColor.CGColor;
    [self setNeedsDisplay:YES];
}

- (void) drawRect:(CGRect)rect
{
   // [super drawRect: rect];
    
    
    assert(self.marks.count != 0);
    
   CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext]
                                          graphicsPort];
    
//    CGContextSetAllowsFontSubpixelQuantization(context, true);
//    CGContextSetShouldSubpixelQuantizeFonts(context, true);
//    CGContextSetAllowsFontSubpixelPositioning(context, true);
//    CGContextSetShouldSubpixelPositionFonts(context, false);
 //   CGContextSetAllowsAntialiasing(context,true);
    CGContextSetShouldSmoothFonts(context, true);
    CGContextSetAllowsFontSmoothing(context,true);
    
    
    
    if(self.backgroundColor) {
         [self.backgroundColor setFill];
    } else {
        
    //    CGContextSetFillColorWithColor(context, self.layer.backgroundColor);
        
       // [NSColorFromRGB(0xffffff) setFill];
    }
    
  //  CGContextSetFillColorWithColor(context, self.layer.backgroundColor);
    
   NSRectFill(self.bounds);
    
    
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    
    CGPathAddRect(path, NULL, self.bounds);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) self.attributedString);
    
    if(CTFrame)
        CFRelease(CTFrame);
    
    CTFrame = CTFramesetterCreateFrame(framesetter,
                                                CFRangeMake(0, 0), path, NULL);
    
    
   CGContextSaveGState(context);
    
    CTFrameDraw(CTFrame, context);
    
    CFRelease(path);
    CFRelease(framesetter);
    
    
    
    
    if(!_isEditable)
        return;
    
    _selectRange = NSMakeRange(NSNotFound, 0);
    
   
    [self.marks enumerateObjectsUsingBlock:^(TGCTextMark *mark, NSUInteger idx, BOOL *stop) {
        
        if( (currentSelectPosition.x != -1 && currentSelectPosition.y != -1) ||  mark.range.location != NSNotFound) {
            
            NSRange lessRange = mark.range;
            
            
            CFArrayRef lines = CTFrameGetLines(CTFrame);
            
            CGPoint origins[CFArrayGetCount(lines)];
            
            CTFrameGetLineOrigins(CTFrame, CFRangeMake(0, 0), origins);
            
            int startSelectLineIndex = [self lineIndex:origins count:(int) CFArrayGetCount(lines) location:startSelectPosition];
            
            int currentSelectLineIndex = [self lineIndex:origins count:(int) CFArrayGetCount(lines) location:currentSelectPosition];
            
            
            int dif = abs(startSelectLineIndex - currentSelectLineIndex);
            
            if(mark.range.location != NSNotFound) {
                startSelectLineIndex = 0;
                currentSelectLineIndex = (int) CFArrayGetCount(lines) - 1;
                dif = 0;
            }
            
           
            
            
            BOOL isReversed = currentSelectLineIndex < startSelectLineIndex;
            
            
            for (int i = startSelectLineIndex; isReversed ? i >= currentSelectLineIndex : i <= currentSelectLineIndex ; isReversed ? i-- : i++)
            {
                
                
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                
                CFRange lineRange = CTLineGetStringRange(line);
                
                
                CFIndex startIndex,endIndex;
                
                if(mark.isReal) {
                    startIndex  = CTLineGetStringIndexForPosition(line, startSelectPosition);
                    
                    endIndex = CTLineGetStringIndexForPosition(line, currentSelectPosition);
                }
                
                if((lineRange.location + lineRange.length) >= lessRange.location ) {
                    if(lessRange.length > 0) {
                        
                        startIndex = lessRange.location;
                        
                        NSUInteger maxPos = lineRange.length + lineRange.location;
                        
                        
                        
                        NSUInteger maxSelect = maxPos - startIndex;
                        
                        int select = (int) MIN(maxSelect,lessRange.length);
                        
                        
                        lessRange.length-=select;
                        lessRange.location+=select;
                        
                        
                        endIndex = startIndex + select;
                        
                        
                    }
                    
                }
                
                
                if( dif > 0 ) {
                    if(i != currentSelectLineIndex) {
                        endIndex = ( lineRange.length + lineRange.location );
                    }
                    
                    if(i != startSelectLineIndex) {
                        startIndex = lineRange.location;
                    }
                    
                    if(isReversed) {
                        
                        if(i == startSelectLineIndex) {
                            endIndex = startIndex;
                            startIndex = lineRange.location;
                        }
                        
                        if(i == currentSelectLineIndex) {
                            startIndex = endIndex;
                            endIndex = ( lineRange.length + lineRange.location );
                        }
                        
                    }
                    
                }
                
                
                if(startIndex > endIndex) {
                    startIndex = endIndex+startIndex;
                    endIndex = startIndex - endIndex;
                    startIndex = startIndex - endIndex;
                }
                
                if(mark.isReal) {
                    if(_selectRange.location == NSNotFound || _selectRange.location > startIndex) {
                        _selectRange.location = startIndex;
                    }
                    
                    _selectRange.length +=  (endIndex - startIndex);
                }
                
               
                
                
                CGFloat ascent, descent, leading;
                
                CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                
                int startOffset = CTLineGetOffsetForStringIndex(line, startIndex, NULL);
                int endOffset = CTLineGetOffsetForStringIndex(line, endIndex, NULL);
                
                
                width = (endOffset -startOffset);
                
                CGRect runBounds = CGRectZero;
                
                
                runBounds.size.width = width;
                runBounds.size.height = floor(ascent + ceil(descent) + leading);
                
                
                runBounds.origin.x = startOffset;
                runBounds.origin.y = origins[i].y - ceil(descent - leading);
                
                
                NSColor *color = mark ? mark.color : self.selectColor;
                
                if(!color)
                    color =  NSColorFromRGBWithAlpha(0x1d80cc, 0.5);
                
                CGContextSetFillColorWithColor(context, color.CGColor);
                CGPathRef highlightPath = [self pathForRoundedRect:runBounds radius:0];
                CGContextAddPath(context, highlightPath);
                CGContextFillPath(context);
                CGPathRelease(highlightPath);
                
                
                // CFRelease(line);
                
                
            }
        }

        
        
    }];
    
    
    
    CGContextRestoreGState(context);
    
}

-(BOOL)becomeFirstResponder {

    [self.window makeFirstResponder:self];

    return YES;
}


-(BOOL)resignFirstResponder {
    [self _resignFirstResponder];

    return [super resignFirstResponder];
}

-(void)_resignFirstResponder {
    [self setSelectionRange:NSMakeRange(NSNotFound, 0)];
}


-(BOOL)respondsToSelector:(SEL)aSelector {
    
    
    if(aSelector == @selector(copy:)) {
        return self.selectRange.location != NSNotFound;
    }
 
    return [super respondsToSelector:aSelector];
}

-(void)copy:(id)sender {
    
    if(self.selectRange.location != NSNotFound) {
        NSPasteboard* cb = [NSPasteboard generalPasteboard];
        
        [cb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
        [cb setString:[self.attributedString.string substringWithRange:self.selectRange] forType:NSStringPboardType];
    }
    
    
}



static const int lineHeight = 15;


-(BOOL)isCurrentLine:(NSPoint)position linePosition:(NSPoint)linePosition {
    return (position.y > linePosition.y) && position.y < (linePosition.y + lineHeight);
}

-(int)selectLinesCount {
    return ceil( abs( startSelectPosition.y - currentSelectPosition.y ) % lineHeight );
}


-(int)lineIndex:(CGPoint[])origins count:(int)count location:(NSPoint)location { // fix this method
    
    for (int i = 0; i < count; i++) {
        if([self isCurrentLine:location linePosition:origins[i]])
            return i;
    }
    
    return location.y < 3 ? (count-1) : 0 ;
}



-(void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
    [self _mouseDown:theEvent];
    
}




-(int)currentIndexInLocation:(NSPoint)location {
    
    CFArrayRef lines = CTFrameGetLines(CTFrame);
    
    CGPoint origins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(CTFrame, CFRangeMake(0, 0), origins);
    
    int lineIdx = [self lineIndex:origins count:(int)CFArrayGetCount(lines) location:location];
    
    CTLineRef lineRef = CFArrayGetValueAtIndex(lines, lineIdx);
    
    int width = CTLineGetTypographicBounds(lineRef, NULL, NULL, NULL);
    
    if( (NSMinX(self.frame) + width) > location.x && location.x > NSMinX(self.frame)) {
        int index = (int) CTLineGetStringIndexForPosition(lineRef, location);
        return index == self.attributedString.length ? index-1 : index;
    }
    
   
    return -1;
}

-(BOOL)indexIsSelected:(int)index {
    return self.selectRange.location <= index && (self.selectRange.location + self.selectRange.length) > index;
}


-(void)_mouseDown:(NSEvent *)theEvent {
    if(!_isEditable)
        return;
    
    startSelectPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    currentSelectPosition = NSMakePoint(-1, -1);
    [self setSelectionRange:NSMakeRange(NSNotFound, 0)];
    
    [self setNeedsDisplay:YES];
}

-(BOOL)_checkClickCount:(NSEvent *)theEvent {
    if(theEvent.clickCount == 3) {
        [self setSelectionRange:NSMakeRange(0, self.attributedString.length)];
        
         _selectRange = NSMakeRange(0, self.attributedString.length);
        
    } else if(theEvent.clickCount == 2) {
       
        
        int startIndex = [self currentIndexInLocation:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
        
        if(startIndex == -1)
            return NO;
        
        
        int prev = startIndex ;
        
        int next = startIndex ;
        
        
        
        NSRange range = NSMakeRange(startIndex == 0 ? 0 : (startIndex == self.attributedString.length ? startIndex - 1 : startIndex), 1);
        
        NSString *currentChar = [self.attributedString.string substringWithRange:NSMakeRange(range.location, 1)];
        
        BOOL valid = [[currentChar stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqualToString:@""];
        
        while (valid) {
            
            
            NSString *prevChar = [self.attributedString.string substringWithRange:NSMakeRange(prev, 1)];
            NSString *nextChar = [self.attributedString.string substringWithRange:NSMakeRange(next, 1)];
            
            
            BOOL prevValid = [[prevChar stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqualToString:@""];
            BOOL nextValid = [[nextChar stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqualToString:@""];
            
            if (prevValid && prev > 0) {
                --prev;
            }
            
            
            if(nextValid && next < self.attributedString.length - 1) {
                ++next;
            }
            
            range.location = prevValid ? prev : prev + 1;
            
            range.length =  next - range.location;
            
            if(prev == 0)
                prevValid = NO;
            
            if(next == self.attributedString.length - 1) {
                 nextValid = NO;
                 range.length++;
            }
            
            
           
            if(!prevValid && !nextValid)
                break;
            
            if((prev == 0 && !nextValid)) {
                break;
            }
            
            
            
        }
        
        [self setSelectionRange:range];
        
        _selectRange = range;
        
    }
    
    return theEvent.clickCount == 2 || theEvent.clickCount == 3;
}

-(void)mouseDragged:(NSEvent *)theEvent {
    [super mouseDragged:theEvent];
    
    [[NSCursor IBeamCursor] set];
    
    [self _mouseDragged:theEvent];
}


-(void)_mouseDragged:(NSEvent *)theEvent {
    if(!_isEditable)
        return;
    
    currentSelectPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    [self setNeedsDisplay:YES];
}

-(void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    [self checkCursor:theEvent];
}



-(NSString *)linkAtPoint:(NSPoint)location hitTest:(BOOL *)hitTest {
    if([self hitTest:location]) {
        CFArrayRef lines = CTFrameGetLines(CTFrame);
        
        CGPoint origins[CFArrayGetCount(lines)];
        CTFrameGetLineOrigins(CTFrame, CFRangeMake(0, 0), origins);
        
        int line = [self lineIndex:origins count:(int)CFArrayGetCount(lines) location:location];
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, line);
        
        CGFloat ascent,descent,leading;
        
        int width = CTLineGetTypographicBounds(lineRef, &ascent, &descent, &leading);
        
        if( (NSMinX(self.frame) + width) > location.x && location.x > NSMinX(self.frame)) {
            NSRange range;
            
            int position = (int) CTLineGetStringIndexForPosition(lineRef, location);
            
            NSString *link;
            
            if(position < 0)
                position = 0;
            if(position >= self.attributedString.length)
                position = (int)self.attributedString.length - 1;
            
            
            NSDictionary *attrs = [self.attributedString attributesAtIndex:position effectiveRange:&range];
            link = [attrs objectForKey:NSLinkAttributeName];
            
            *hitTest = YES;
            
            return link;
        }
    }
    
    return nil;
}


-(void)checkCursor:(NSEvent *)theEvent {
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if([self hitTest:location]) {
        
        BOOL hitTest;
        
        NSString *link = [self linkAtPoint:location hitTest:&hitTest];
        
        if(hitTest) {
            if(link) {
                [[NSCursor pointingHandCursor] set];
            } else {
                if(_isEditable)
                    [[NSCursor IBeamCursor] set];
            }
            if(_isEditable)
                 return;
        }
    }
    
    [[NSCursor arrowCursor] set];
}

-(void)mouseMoved:(NSEvent *)theEvent {
    [self checkCursor:theEvent];
}

-(void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    [[NSCursor arrowCursor] set];
}


-(void)mouseUp:(NSEvent *)theEvent {
    
    if(self.selectRange.location == NSNotFound) {
        NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        BOOL hitTest;
        NSString *link = [self linkAtPoint:location hitTest:&hitTest];
        
        if(link) {
            open_link(link);
        }
    } else {
        [super mouseUp:theEvent];
    }
    
    [self _checkClickCount:theEvent];
    
    [[NSCursor arrowCursor] set];
}


-(void)rightMouseDown:(NSEvent *)theEvent {
    
    if(self.selectRange.location != NSNotFound) {
        NSTextView *view = (NSTextView *) [self.window fieldEditor:YES forObject:self];
        [view setEditable:NO];
        
        [view setString:self.attributedString.string];
        
        [view setSelectedRange:NSMakeRange(0, view.string.length)];
        
        
        [NSMenu popUpContextMenu:[view menuForEvent:theEvent] withEvent:theEvent forView:view];
    }
}



- (CGPathRef)pathForRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
    CGMutablePathRef retPath = CGPathCreateMutable();
    
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
    
    CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
    CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
    CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
    CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
    CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
    CGPathCloseSubpath(retPath);
    
    return retPath;
}


@end