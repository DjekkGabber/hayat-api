package uz.hayatbank.api.transport.argument;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericArgument;

@EqualsAndHashCode(callSuper = true)
@Data
public class ChangeSelfInfoArgument extends GenericArgument {
    private String fio;
    private String email;
}
