//
//  StateMachineChainTests.swift
//  SwiftState
//
//  Created by Yasuhiro Inami on 2014/08/04.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import SwiftState
import XCTest

class StateMachineChainTests: _TestCase
{    
    func testAddRouteChain()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteChain(.State0 => .State1 => .State2) { context in
            invokeCount++
            return
        }
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")
        
        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.State2 => .State0)   // make sure to add routes
        machine <- .State0
        
        // tryState 0 => 1 => 2 again
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 2, "Handler should be performed again.")
    }
    
    func testAddRouteChain_condition()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var flag = false
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteChain(.State0 => .State1 => .State2, condition: flag) { context in
            invokeCount++
            return
        }
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 0, "Handler should NOT be performed because flag=false.")
        
        //
        // reset: tryState 2 => 0
        //
        machine.addRoute(.State2 => .State0)   // make sure to add routes
        machine <- .State0
        
        flag = true
        
        // tryState 0 => 1 => 2
        machine <- .State1
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed.")
    }
    
    func testAddRouteChain_failBySkipping()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteChain(.State0 => .State1 => .State2) { context in
            XCTFail("Handler should NOT be performed because 0 => 2 is skipping 1.")
        }
        
        // tryState 0 => 2 directly (skipping 1)
        machine <- .State2
    }
    
    func testAddRouteChain_failByHangingAround()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        // add 0 => 1 => 2
        machine.addRouteChain(.State0 => .State1 => .State2) { context in
            XCTFail("Handler should NOT be performed because 0 => 1 => 3 => 2 is hanging around 3.")
        }
        machine.addRoute(.State1 => .State3)    // add 1 => 3 route for hanging around
        
        // tryState 0 => 1 => 3 => 2 (hanging around 3)
        machine <- .State1
        machine <- .State3
        machine <- .State2
    }
    
    func testAddRouteChain_succeedByFailingHangingAround()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        machine.addRouteChain(.State0 => .State1 => .State2) { context in
            invokeCount++
            return
        }
        // machine.addRoute(.State1 => .State3)    // comment-out: 1 => 3 is not possible
        
        // tryState 0 => 1 => 3 => 2 (cannot hang around 3)
        machine <- .State1
        machine <- .State3
        machine <- .State2
        
        XCTAssertEqual(invokeCount, 1, "Handler should be performed because 1 => 3 is not registered, thus performing 0 => 1 => 2.")
    }
    
    func testRemoveRouteChain()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        let (routeID, handlerID) = machine.addRouteChain(.State0 => .State1 => .State2) { context in
            invokeCount++
            return
        }
        
        // removeRoute
        machine.removeRoute(routeID)
        
        // tryState 0 => 1
        let success = machine <- .State1
        
        XCTAssertFalse(success, "RouteChain should be removed.")
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")
    }
    
    func testRemoveChainHandler()
    {
        let machine = StateMachine<MyState, String>(state: .State0)
        
        var invokeCount = 0
        
        // add 0 => 1 => 2
        let (routeID, handlerID) = machine.addRouteChain(.State0 => .State1 => .State2) { context in
            invokeCount++
            return
        }
        
        // removeHandler
        XCTAssertTrue(machine.removeHandler(handlerID))
        
        // tryState 0 => 1 => 2
        machine <- .State1
        let success = machine <- .State2
        
        XCTAssertTrue(success, "0 => 1 => 2 should be successful.")
        XCTAssertEqual(invokeCount, 0, "ChainHandler should NOT be performed.")
    }
}