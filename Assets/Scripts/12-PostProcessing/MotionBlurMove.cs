using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class MotionBlurMove : MonoBehaviour
{
    private Transform _transform;
    private MoveDir _moveDir = MoveDir.Forward;
    public float speed = 5f;

    private enum MoveDir
    {
        Forward,
        Back,
        Left,
        Right,
    }
    void Start()
    {
        _transform = this.transform;
    }
    
    void Update()
    {
        switch (_moveDir)
        {
            case MoveDir.Forward:
                transform.position = transform.position + Vector3.forward * speed;
                _moveDir = MoveDir.Back;
                break;
            case MoveDir.Back:
                transform.position = transform.position + Vector3.back * speed;
                _moveDir = MoveDir.Left;
                break;
            case MoveDir.Left:
                transform.position = transform.position + Vector3.left * speed;
                _moveDir = MoveDir.Right;
                break;
            case MoveDir.Right:
                transform.position = transform.position + Vector3.right * speed;
                _moveDir = MoveDir.Forward;
                break;
        }
    }
}
