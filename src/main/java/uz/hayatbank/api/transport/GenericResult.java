package uz.hayatbank.api.transport;

import lombok.Data;

import java.io.Serializable;

@Data
public class GenericResult implements Serializable {
    private Integer code = -1;
    private String message = "Internal error";
}
