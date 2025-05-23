package uz.hayatbank.api.transport;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class GenericPagingArgument extends GenericArgument {
    private Integer page;
    private Integer per_page;
}
