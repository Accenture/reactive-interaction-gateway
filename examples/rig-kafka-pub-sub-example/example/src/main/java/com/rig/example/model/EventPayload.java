package com.rig.example.model;

import lombok.Data;

@Data
public class EventPayload {
    public String payload;
    public Integer number;

    public EventPayload transform() {
        this.payload = payload + " TRANSFORMED";
        this.number = number * 2;

        return this;
    }
}
