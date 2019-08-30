package com.rig.example.model;

import lombok.Data;

@Data
public class EventBody {
    public String id;
    public String type;
    public String time;
    public String specversion;
    public String source;
    public String contenttype;
    public EventData data;
    public Object rig;
}